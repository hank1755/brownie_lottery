// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBaseV2, Ownable {
    AggregatorV3Interface internal ethUsdPriceFeed;
    address payable[] public players; // array of player addresses
    uint256 public usdEntryFee; // lottery entry fee
    // variables for VRF setting:
    uint32 constant callbackGasLimit = 1_000_000; // required by chainlink for gas to return result
    uint256 internal fee;
    bytes32 internal keyHash;
    uint16 constant requestConfirmations = 3; // number of confirmations for link to confirm, min 3 blocks
    uint32 constant numWords = 1; // number of random number returned by chainlink

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        PICK_WINNER
    }

    LOTTERY_STATE public lottery_state; // status of lottery: started/stopped

    struct LOTTERY_WINNERS {
        uint256 randomWords; // chainlink randomWords return
        address winner; //address of most recenter winner
    }

    mapping(uint256 => LOTTERY_WINNERS) public lottery_winners; // requestID to the LOTTERY_WINNERS

    // Coordinator for VRF request
    VRFCoordinatorV2Interface COORDINATOR;

    // useful to transfer LINK to subscription
    LinkTokenInterface LINKTOKEN;

    // Your subscription ID.
    uint64 public s_subscriptionId;
    uint256[] public s_randomWords;
    uint256 public s_requestId;

    event requestRandomWords(uint256 requestId);
    event subscriptionCreation(uint64 subscriptionId);

    constructor(
        address _priceFeedAddress,
        bytes32 _keyHash,
        uint256 _fee,
        address _vrfCoordinator
    ) {
        // for vrf requires vrf coord address and link token address
        usdEntryFee = 50 * (10 ** 18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        keyHash = _keyHash;
        fee = _fee;
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        // $50 USD min
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        // get eth usd price from chainlink feed
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // convert feed price to 18 decimals: price feed 8 + 10
        uint256 adjustedprice = uint256(price) * (10 ** 10);
        // set price of entry from usd to eth-gwei
        uint256 costToEnter = uint256(usdEntryFee) / uint256(adjustedprice);
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Lottery is already started"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Lottery is already stopped"
        );

        lottery_state = LOTTERY_STATE.PICK_WINNER;

        uint256 requestId = requestRandomWords(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
    }

    // chainlink override function for vrf callback.
    // returns the vrf (_randomWords) to be used in the function
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(lottery_state == LOTTERY_STATE.PICK_WINNER, "U not there yet");
        require(_requestId > 0, "random-not-found");
        lottery_state = LOTTERY_STATE.CLOSED;
        uint256 indexOfWinner = _randomWords[0] % players.length;
        payable(players[indexOfWinner]).transfer(address(this).balance);
        players = new address payable[](0);

        // update struct
        lottery_winners[_requestId].randomWords = _randomWords[0];
        lottery_winners[_requestId].winner = players[indexOfWinner];
    }
}
