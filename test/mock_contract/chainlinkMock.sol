// MockAggregator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockAggregator {
    int256 public answer;
    uint256 public updatedAt;

    constructor(int256 _answer, uint256 _updatedAt) {
        answer = _answer;
        updatedAt = _updatedAt;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (0, answer, 0, updatedAt, 0);
    }

    function updateAnswer(int256 _newAnswer) external {
        answer = _newAnswer;
        updatedAt = block.timestamp;
    }
}
