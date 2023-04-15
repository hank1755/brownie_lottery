// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Mocks is VRFConsumerBaseV2 {
    event RandomWordsTaken(uint256[] randomWords);

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 vrfSubscriptionId;
    bytes32 vrfKeyHash;
    uint32 vrfCallbackGasLimit = 100000;
    uint16 vrfRequestConfirmations = 3;
    uint32 vrfNumWords = 1;
    uint256 vrfRequestId;
    uint256[] randomWords;

    AggregatorV3Interface ethUsdPriceFeed;

    constructor(
        address _vrfCoordinatorAddress,
        bytes32 _vrfKeyHash,
        uint64 _vrfSubscriptionId,
        address _priceFeedAddress
    ) VRFConsumerBaseV2(_vrfCoordinatorAddress) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinatorAddress);
        vrfKeyHash = _vrfKeyHash;
        vrfSubscriptionId = _vrfSubscriptionId;

        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function getRandomWords() public {
        requestRandomWords();
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();

        return uint256(price);
    }

    function requestRandomWords() private {
        // Will revert if subscription is not set and funded.
        vrfRequestId = COORDINATOR.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            vrfRequestConfirmations,
            vrfCallbackGasLimit,
            vrfNumWords
        );
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory _randomWords
    ) internal override {
        randomWords = _randomWords;

        emit RandomWordsTaken(_randomWords);
    }
}
