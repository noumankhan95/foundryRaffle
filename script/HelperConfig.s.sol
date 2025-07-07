//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {V3AggregatorMock} from "test/Mocks/V3AggregatorMock.sol";
import {VRFMock} from "test/Mocks/VRFMock.sol";

contract HelperConfig {
    struct NetworkConfig {
        uint256 _updateInterval;
        AggregatorV3Interface _priceFeed;
        bytes32 keyHash;
        uint256 subId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        bytes extraArgs;
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1) {} else if (block.chainid == 11155111) {
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

    function getEthConfig() external view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                _updateInterval: 60,
                _priceFeed: AggregatorV3Interface(
                    0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
                ),
                keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e984b2f7c8c9d8e2f8e2f8e2f8e,
                subId: 1234,
                requestConfirmations: 3,
                callbackGasLimit: 100000,
                numWords: 1,
                extraArgs: ""
            });
    }

    function getSepoliaEthConfig()
        internal
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                _updateInterval: 60,
                _priceFeed: AggregatorV3Interface(
                    0x694AA1769357215DE4FAC081bf1f309aDC325306
                ),
                keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e984b2f7c8c9d8e2f8e2f8e2f8e,
                subId: 1234,
                requestConfirmations: 3,
                callbackGasLimit: 100000,
                numWords: 1,
                extraArgs: ""
            });
    }

    function getAnvilEthConfig() internal returns (NetworkConfig memory) {
        V3AggregatorMock priceFeed = new V3AggregatorMock(18, 2000 * 10 ** 18);
        VRFMock vrfMock = new VRFMock(0.1 * 10 ** 18, 0.0001 * 10 ** 18);
        return
            NetworkConfig({
                _updateInterval: 60,
                _priceFeed: AggregatorV3Interface(address(priceFeed)),
                keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e984b2f7c8c9d8e2f8e2f8e2f8e,
                subId: 1234,
                requestConfirmations: 3,
                callbackGasLimit: 100000,
                numWords: 1,
                extraArgs: ""
            });
    }
}
