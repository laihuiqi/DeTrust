// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BondContract {
    address issuer;
    string bondName;
    string bondCode;
    uint256 issueQuantity;
    uint256 issueDate;
    uint256 maturityDate;
    uint256 couponRate;
    uint256 couponPaymentInterval;
    uint256 bondPrice;
    uint256 faceValue;
    uint256 redemptionValue;
    uint256 bondYield;

    mapping(address => uint256) public holders;

    constructor(address _issuer, string memory _bondName, string memory _bondCode, 
        uint256 _issueQuantity, uint256 _issueDate, uint256 _maturityDate, uint256 _couponRate, 
        uint256 _couponPaymentInterval, uint256 _bondPrice, uint256 _faceValue, uint256 _redemptionValue, 
        uint256 _bondYield) {
        issuer = _issuer;
        bondName = _bondName;
        bondCode = _bondCode;
        issueQuantity = _issueQuantity;
        issueDate = _issueDate;
        maturityDate = _maturityDate;
        couponRate = _couponRate;
        couponPaymentInterval = _couponPaymentInterval;
        bondPrice = _bondPrice;
        faceValue = _faceValue;
        redemptionValue = _redemptionValue;
        bondYield = _bondYield;
    }

    function buy(uint256 _quantity) public {
        // buy the bond
    }

    function transfer(address _transferee) public {
        // sell the bond
    }

    function repay() public {
        // repay the bond
    }
}