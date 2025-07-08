//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {VRFMock} from "../test/Mocks/VRFMock.sol";
import {LinkToken} from "../test/Mocks/ERC20Link.sol";
import {Script} from "forge-std/Script.sol";

contract CreateSubscription is Script {
    function createSubscriptionForLocal(
        address vrfCordinator,
        address account
    ) external returns (uint64 subId) {
        vm.startBroadcast(account);
        subId = VRFMock(vrfCordinator).createSubscription();
        vm.stopBroadcast();
    }
}

contract FundContract is Script {
    uint64 private constant LOCAL_CHAIN_ID = 31337;

    function fundTheLocalSubscription(
        address vrfCordinator,
        uint64 subId,
        uint64 _amount,
        address linkToken,
        address account
    ) external {
        vm.startBroadcast(account);
        if (block.chainid == LOCAL_CHAIN_ID) {
            VRFMock(vrfCordinator).fundSubscription(subId, _amount);
        } else {
            bool success = LinkToken(linkToken).transferAndCall(
                vrfCordinator,
                _amount,
                abi.encode(subId)
            );
            if (!success) {
                revert("Transfer and call failed");
            }
        }
        vm.stopBroadcast();
    }
}

contract AddConsumer is Script {
    function addConsumerToLocalSubscription(
        address vrfCordinator,
        uint64 subId,
        address consumer,
        address account
    ) external {
        vm.startBroadcast(account);
        VRFMock(vrfCordinator).addConsumer(subId, consumer);
        vm.stopBroadcast();
    }
}
