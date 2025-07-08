//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployContract} from "script/DeployContract.s.sol";
import {Raffle} from "src/Raffle.sol";

contract TestRaffle is Test {
    HelperConfig.NetworkConfig activeNetworkConfig;
    DeployContract deployContract;
    Raffle raffleContract;

    function setUp() external {
        deployContract = new DeployContract();
        activeNetworkConfig = deployContract.getActiveNetworkConfig();
        raffleContract = deployContract.getRaffleContract();
    }

    function testOwnerisThisContract() external {
        assert(raffleContract.getOwner() == activeNetworkConfig.account);
    }
}
