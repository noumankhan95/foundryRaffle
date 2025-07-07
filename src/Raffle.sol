//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AutomationCompatibleInterface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./PriceConverter.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is AutomationCompatibleInterface, VRFConsumerBaseV2Plus {
    error Raffle__NotEnoughEth(uint256 ethAmount, uint256 minimumUSD);
    error Raffle__NotOwner();
    error Raflle__CantCallWinner();
    error Raffle__UpkeepNotNeeded(uint256, uint256, uint256);
    error Raffle__CouldntTransferToWinner();
    using PriceConverter for uint256;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event WinnerPicked(address);
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    enum RAFFLE_STATUS {
        OPEN,
        CALCULATING
    }

    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    //CONTRACT VARIABLES
    address private immutable i_owner;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    uint256 internal constant Minimum_USD = 5 * 10e18;
    address[] public s_participants;
    mapping(address => uint256) s_participantsAmount;
    RAFFLE_STATUS private s_raffleState;
    address public s_prevWinner;
    //VRF AND AUTOMATION VARS
    uint256[] public requestIds;
    uint256 public lastRequestId;
    AggregatorV3Interface internal immutable i_priceFeed;
    uint256 private immutable i_updateInterval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subId;
    uint16 private constant requestConfirmations = 5;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant numWords = 5;
    bytes private i_extraArgs;

    constructor(
        uint256 _updateInterval,
        AggregatorV3Interface _priceFeed,
        bytes32 keyHash,
        uint256 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        bytes memory extraArgs
    )
        AutomationCompatibleInterface()
        VRFConsumerBaseV2Plus(address(_priceFeed))
    {
        i_owner = msg.sender;
        interval = _updateInterval;
        lastTimeStamp = block.timestamp;
        i_priceFeed = _priceFeed;
        i_keyHash = keyHash;
        i_subId = subId;
        i_callbackGasLimit = callbackGasLimit;
    }

    modifier minEthAmount() {
        if (msg.value.getPrice(i_priceFeed) < Minimum_USD) {
            revert Raffle__NotEnoughEth({
                ethAmount: msg.value,
                minimumUSD: Minimum_USD
            });
        }
        _;
    }

    function enterRaffle() external payable minEthAmount {
        s_participants.push(msg.sender);
        s_participantsAmount[msg.sender] = msg.value;
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded =
            ((block.timestamp - lastTimeStamp) > interval) &&
            s_raffleState == RAFFLE_STATUS.OPEN &&
            s_participants.length > 0 &&
            address(this).balance > 0;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_participants.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RAFFLE_STATUS.CALCULATING;
        requestRandomWords(true);
    }

    function requestRandomWords(
        bool enableNativePayment
    ) internal onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override onlyOwner {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
        uint256 winnerIndex = s_participants.length % _randomWords[0];
        address winnerAddress = s_participants[winnerIndex];
        emit WinnerPicked(winnerAddress);
        s_prevWinner = winnerAddress;
        (bool success, ) = payable(winnerAddress).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert Raffle__CouldntTransferToWinner();
        }
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    receive() external payable {}

    fallback() external payable {}
}
