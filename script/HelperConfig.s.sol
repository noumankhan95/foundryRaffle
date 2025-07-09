//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {V3AggregatorMock} from "test/Mocks/V3AggregatorMock.sol";
import {VRFMock} from "test/Mocks/VRFMock.sol";
import {LinkToken} from "test/Mocks/ERC20Link.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract HelperConfig is Script {
    address public constant FOUNDRY_DEFAULT_SENDER =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    struct NetworkConfig {
        uint256 _updateInterval;
        AggregatorV3Interface _priceFeed;
        bytes32 keyHash;
        uint256 subId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        bytes extraArgs;
        address account;
        address vrfCoordinatorV2_5;
        address linkToken;
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getEthConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilEthConfig();
        } else {
            revert("Unsupported network");
        }
    }

    function getConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getEthConfig() internal pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                _updateInterval: 60,
                _priceFeed: AggregatorV3Interface(
                    0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
                ),
                keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e984b2f7c8c9d8e2f8e2f8e2f8e,
                subId: 0,
                requestConfirmations: 3,
                callbackGasLimit: 100000,
                numWords: 1,
                extraArgs: "",
                account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                vrfCoordinatorV2_5: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
                linkToken: 0x514910771AF9Ca656af840dff83E8264EcF986CA
            });
    }

    function getSepoliaEthConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                _updateInterval: 60,
                _priceFeed: AggregatorV3Interface(
                    0x694AA1769357215DE4FAC081bf1f309aDC325306
                ),
                keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e984b2f7c8c9d8e2f8e2f8e2f8e,
                subId: 0,
                requestConfirmations: 3,
                callbackGasLimit: 100000,
                numWords: 1,
                extraArgs: "",
                account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function getAnvilEthConfig() internal returns (NetworkConfig memory) {
        vm.startBroadcast(FOUNDRY_DEFAULT_SENDER);
        vm.deal(FOUNDRY_DEFAULT_SENDER, 100 ether);
        V3AggregatorMock priceFeed = new V3AggregatorMock(18, 2000 * 1e18);
        VRFMock vrfMock = new VRFMock(0.025 ether, 1e9);
        console.log("in helper config", address(vrfMock));
        uint256 subId = vrfMock.createSubscription();
        (
            uint96 balance,
            uint96 nativeBalance,
            uint64 reqCount,
            address subOwner,
            address[] memory consumers
        ) = vrfMock.getSubscription(subId);

        LinkToken linkTokenAddress = new LinkToken();
        vm.stopBroadcast();
        return
            NetworkConfig({
                _updateInterval: 60,
                _priceFeed: AggregatorV3Interface(address(priceFeed)),
                keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e984b2f7c8c9d8e2f8e2f8e2f8e,
                subId: subId,
                requestConfirmations: 3,
                callbackGasLimit: 500000,
                numWords: 1,
                extraArgs: "",
                account: FOUNDRY_DEFAULT_SENDER,
                vrfCoordinatorV2_5: address(vrfMock),
                linkToken: address(linkTokenAddress)
            });
    }
}
