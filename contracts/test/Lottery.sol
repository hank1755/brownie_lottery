// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    address payable[] public players; // array of player addresses
    uint256 public usdEntryFee; // lottery entry fee
    AggregatorV3Interface internal ethUsdPriceFeed; //

    constructor(address _priceFeedAddress) Ownable() {
        usdEntryFee = 50 * (10 ** 18); // usd in gwei
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress); // get price of ethusd
    }

    function enter() public payable {
        // $50 USD min
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        // get eth usd price from chainlink feed
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // convert feed price to 18 decimals: price feed 8 + 10
        uint256 adjustedprice = uint256(price) * (10 ** 10);
        // set price of entry from usd to eth-gwei
        uint256 costToEnter = (uint256(usdEntryFee) * (10 ** 18)) /
            uint256(adjustedprice);
        return costToEnter;
    }

    function startLottery() public {}

    function endLotery() public {}
}
