// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract CustomizedAggregatorV3Contract is AggregatorV3Interface, Ownable {
    string private _currency;
    uint8 private _decimals;
    uint256 private _deployTime;
    int256 private _currentAnswer;
    uint256 private _updateTime;

    constructor(string memory currency_, uint8 decimals_, int256 initAnswer){
        _currency = currency_;
        _decimals = decimals_;
        _deployTime = block.timestamp;
        _currentAnswer = initAnswer;
        _updateTime = block.timestamp;
    }

    function updateAnswer(int256 newAnswer) external onlyOwner {
        _currentAnswer = newAnswer;
        _updateTime = block.timestamp;
    }

    function currency() external view returns (string memory) {
        return _currency;
    }

    function decimals() external view returns (uint8){
        return _decimals;
    }

    function description() external view returns (string memory){
        return string.concat(string.concat("Simple exchange aggregator from ", _currency) ," to USD");
    }

    function version() external view returns (uint256){
        return 1;
    }

    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ){
        return _latestRoundData();
    }

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ){
        return _latestRoundData();
    }

    function _latestRoundData()
    internal
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ){
        return (uint80(block.timestamp), _currentAnswer, block.timestamp, block.timestamp, uint80(0));
    }
}
