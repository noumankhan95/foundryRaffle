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
    using PriceConverter for uint256;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    uint256[] public requestIds;
    uint256 public lastRequestId;
    address private immutable i_owner;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    uint256 internal constant Minimum_USD = 5 * 10e18;
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

    modifier onlyOwnerCanCall() {
        if (msg.sender == i_owner) {
            revert Raffle__NotOwner();
        }
        _;
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

    function enterRaffle() external payable minEthAmount {}

    function pickWinner() internal {}

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
        }
    }

    function requestRandomWords(
        bool enableNativePayment
    ) external onlyOwner returns (uint256 requestId) {
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
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
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
