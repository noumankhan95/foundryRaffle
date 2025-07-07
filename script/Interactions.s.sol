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
    uint64 private constant LOCAL_CHAIN_ID = 31337;

    function fundTheLocalSubscription(
        address vrfCordinator,
        uint64 subId,
        uint64 _amount,
        address linkToken
    ) external {
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
