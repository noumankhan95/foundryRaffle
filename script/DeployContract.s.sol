//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AddConsumer, FundContract, CreateSubscription} from "./Interactions.s.sol";
import {VRFMock} from "../test/Mocks/VRFMock.sol";
import {Script} from "forge-std/Script.sol";

contract DeployContract is Script {
    HelperConfig.NetworkConfig activeNetworkConfig;
    Raffle private immutable raffleContract;
    uint96 public constant MOCK_BASE_FEE = 0.025 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;

    constructor() {
        HelperConfig config = new HelperConfig();
        activeNetworkConfig = config.getConfig();

        if (activeNetworkConfig.subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            activeNetworkConfig.subId = createSubscription
                .createSubscriptionForLocal(
                    activeNetworkConfig.vrfCoordinatorV2_5,
                    activeNetworkConfig.account
                );
        }
        FundContract fundContract = new FundContract();
        fundContract.fundTheLocalSubscription(
            activeNetworkConfig.vrfCoordinatorV2_5,
            activeNetworkConfig.subId,
            3 ether,
            activeNetworkConfig.linkToken,
            activeNetworkConfig.account
        );
        vm.startBroadcast(activeNetworkConfig.account);
        raffleContract = new Raffle(
            activeNetworkConfig._updateInterval,
            activeNetworkConfig._priceFeed,
            activeNetworkConfig.keyHash,
            activeNetworkConfig.subId,
            activeNetworkConfig.requestConfirmations,
            activeNetworkConfig.callbackGasLimit,
            activeNetworkConfig.numWords,
            activeNetworkConfig.extraArgs,
            activeNetworkConfig.vrfCoordinatorV2_5
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumerToLocalSubscription(
            activeNetworkConfig.vrfCoordinatorV2_5,
            activeNetworkConfig.subId,
            address(raffleContract),
            activeNetworkConfig.account
        );
    }

    function getRaffleContract() external view returns (Raffle) {
        return raffleContract;
    }

    function getActiveNetworkConfig()
        external
        view
        returns (HelperConfig.NetworkConfig memory)
    {
        return activeNetworkConfig;
    }
}
