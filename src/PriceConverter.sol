//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getLatestPrice(
        AggregatorV3Interface v3Interface
    ) public view returns (uint256) {
        (, int256 price, , , ) = v3Interface.latestRoundData();
        return uint256(price * 1e10);
    }

    function getPrice(
        uint256 ethAmount,
        AggregatorV3Interface v3Interface
    ) public view returns (uint256) {
        uint256 price = getLatestPrice(v3Interface);
        return (ethAmount * price) / 1e18;
    }
}
