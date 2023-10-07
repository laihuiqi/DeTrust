// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MutualFundContract {
    string fundName;
    string fundDescription;
    address fundManager;
    address[] fundHolders;
    uint256 fundValue;
    uint256 fundShares;
    uint256 yieldRate;
    uint256 interestInterval;
    uint256 commisionRate;

    mapping(address => uint256) public fundShareholders;

    constructor(string memory _fundName, string memory _fundDescription, address _fundManager, 
        uint256 _fundValue, uint256 _yieldRate, uint256 _interestInterval, uint256 _commisionRate) {
        fundName = _fundName;
        fundDescription = _fundDescription;
        fundManager = _fundManager;
        fundValue = _fundValue;
        yieldRate = _yieldRate;
        interestInterval = _interestInterval;
        commisionRate = _commisionRate;
    }

    function buy(uint256 _quantity) public {
        // buy the fund
    }

    function sell(address _transferee) public {
        // sell the fund
    }

    function payInterest() public {
        // pay interest to the fund holders
    }
}