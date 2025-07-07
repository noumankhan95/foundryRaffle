//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {VRFMock} from "../test/Mocks/VRFMock.sol";
import {LinkToken} from "../test/Mocks/ERC20Link.sol";

contract CreateSubscription {
    function createSubscriptionForLocal(
        address vrfCordinator
    ) external returns (uint64 subId) {
        subId = VRFMock(vrfCordinator).createSubscription();
    }
}

contract FundContract {
    function fundTheLocalSubscription(
        address vrfCordinator,
        uint64 subId,
        uint64 _amount
    ) external {
        VRFMock(vrfCordinator).fundSubscription(subId, _amount);
    }
}

contract AddConsumer {
    function addConsumerToLocalSubscription(
        address vrfCordinator,
        uint64 subId,
        address consumer
    ) external {
        VRFMock(vrfCordinator).addConsumer(subId, consumer);
    }
}
