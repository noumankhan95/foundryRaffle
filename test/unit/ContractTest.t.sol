//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployContract} from "script/DeployContract.s.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFMock} from "test/Mocks/VRFMock.sol";
import {console} from "forge-std/console.sol";
import {LinkToken} from "test/Mocks/ERC20Link.sol";

contract TestRaffle is Test {
    HelperConfig.NetworkConfig activeNetworkConfig;
    DeployContract deployContract;
    Raffle raffleContract;
    LinkToken link;

    function setUp() external {
        deployContract = new DeployContract();
        activeNetworkConfig = deployContract.getActiveNetworkConfig();
        raffleContract = deployContract.getRaffleContract();

        // link = LinkToken(activeNetworkConfig.linkToken);

        // // vm.startPrank(msg.sender);
        // if (block.chainid == 31337) {
        //     link.mint(msg.sender, 100 ether);
        //     VRFMock(activeNetworkConfig.vrfCoordinatorV2_5).fundSubscription(
        //         activeNetworkConfig.subId,
        //         100 ether
        //     );
        // }
        // link.approve(activeNetworkConfig.vrfCoordinatorV2_5, 100 ether);
    }

    function testOwnerisDefaultAccount() external {
        assert(raffleContract.getOwner() == activeNetworkConfig.account);
    }

    function testTransactionFailsIfMinimumEthAccount() external {
        address user = makeAddr("User");
        vm.deal(user, 10 ether); // Set user balance to 0.0001 ether
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__NotEnoughEth.selector,
                10,
                5e18 // minimum USD
            )
        );
        vm.startPrank(user);
        raffleContract.enterRaffle{value: 10}();
    }

    function testParticipantsAreAdded() external {
        for (uint8 i = 0; i < 10; i++) {
            address user = makeAddr(string(abi.encodePacked("User", i)));
            vm.deal(user, 10 ether); // Set user balance to 0.0001 ether
            vm.prank(user);
            raffleContract.enterRaffle{value: 1 ether}();
        }
        assert(raffleContract.getParticipants().length == 10);
    }

    function testLotteryWorks() external {
        for (uint8 i = 0; i < 4; i++) {
            address user = makeAddr(string(abi.encodePacked("User", i)));
            vm.deal(user, 10 ether); // Set user balance to 0.0001 ether
            vm.prank(user);
            raffleContract.enterRaffle{value: 1 ether}();
        }
        VRFMock(address(activeNetworkConfig.vrfCoordinatorV2_5))
            .fundSubscription(activeNetworkConfig.subId, 1 ether);
        vm.warp(block.timestamp + raffleContract.getInterval() + 1);
        vm.roll(block.number + 1);
        // vm.expectEmit(true, false, false, false);
        uint256 initialBalance = address(raffleContract).balance;
        (
            uint96 balance,
            uint96 nativeBalance,
            uint64 reqCount,
            address subOwner,
            address[] memory consumers
        ) = VRFMock(address(activeNetworkConfig.vrfCoordinatorV2_5))
                .getSubscription(activeNetworkConfig.subId);

        console.log("Subscription LINK balance:", balance);
        console.log("Subscription Native ETH balance:", nativeBalance);
        console.log("Subscription Request Count:", reqCount);
        console.log("Subscription Owner:", subOwner);
        console.log("Consumers length:", consumers.length);
        vm.prank(activeNetworkConfig.account);
        raffleContract.performUpkeep("");
        assert(
            raffleContract.getRaffleState() == Raffle.RAFFLE_STATUS.CALCULATING
        );
        // VRFMock(address(activeNetworkConfig.vrfCoordinatorV2_5))
        //     .fundSubscriptionWithNative{value: 1 ether}(
        //     activeNetworkConfig.subId
        // );
        // link.transferAndCall(
        //     activeNetworkConfig.vrfCoordinatorV2_5,
        //     1 ether, // or whatever amount you need
        //     abi.encode(activeNetworkConfig.subId)
        // );
        vm.prank(activeNetworkConfig.account);

        VRFMock(address(activeNetworkConfig.vrfCoordinatorV2_5))
            .fulfillRandomWords(
                raffleContract.lastRequestId(),
                address(raffleContract)
            );
        // console.log("Winner address:", raffleContract.s_prevWinner());
        console.log(raffleContract.s_prevWinner().balance);
        console.log(initialBalance);
        assert(raffleContract.getRaffleState() == Raffle.RAFFLE_STATUS.OPEN);
        assert(
            (raffleContract.s_prevWinner().balance - 9 ether) == initialBalance
        );
    }
}
