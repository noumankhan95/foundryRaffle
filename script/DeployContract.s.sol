//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AddConsumer, FundContract, CreateSubscription} from "./Interactions.s.sol";
import {VRFMock} from "../test/Mocks/VRFMock.sol";

contract DeployContract {
    HelperConfig.NetworkConfig activeNetworkConfig;
    Raffle private immutable raffleContract;
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;

    constructor() {
        HelperConfig config = new HelperConfig();
        activeNetworkConfig = config.getConfig();
        if (activeNetworkConfig.subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            uint64 subId = createSubscription.createSubscriptionForLocal(
                activeNetworkConfig.vrfCoordinatorV2_5
            );
            FundContract fundContract = new FundContract();
            fundContract.fundTheLocalSubscription(
                activeNetworkConfig.vrfCoordinatorV2_5,
                subId,
                1e18
            );
        }
        raffleContract = new Raffle(
            activeNetworkConfig._updateInterval,
            activeNetworkConfig._priceFeed,
            activeNetworkConfig.keyHash,
            activeNetworkConfig.subId,
            activeNetworkConfig.requestConfirmations,
            activeNetworkConfig.callbackGasLimit,
            activeNetworkConfig.numWords,
            activeNetworkConfig.extraArgs
        );
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumerToLocalSubscription(
            activeNetworkConfig.vrfCoordinatorV2_5,
            activeNetworkConfig.subId,
            address(raffleContract)
        );
    }

    function getRaffleContract() external view returns (Raffle) {
        return raffleContract;
    }
}
