// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StockContract {
    address issuer;
    address[] premiumHolders;
    string stockName;
    string stockCode;
    uint256 stockValue;
    uint256 authorizedShares;
    uint256 issuedShares; // issued and holding by shareholders
    uint256 dividendRate;

    mapping(address => uint256) public shareholders;

    constructor(address _issuer, address[] memory _premiumHolders, string memory _stockName, string memory _stockCode, uint256 _stockValue, 
        uint256 _authorizedShares, uint256 _issuedShares, uint256 _dividendRate) {
        issuer = _issuer;
        premiumHolders = _premiumHolders;
        stockName = _stockName;
        stockCode = _stockCode;
        stockValue = _stockValue;
        authorizedShares = _authorizedShares;
        issuedShares = _issuedShares;
        dividendRate = _dividendRate;
    }

    function addPremiumHolder(address _premiumHolder) public {
        // add premium holder
    }

    function buy(uint256 _quantity) public {
        // buy the stock
    }

    function sell(address _transferee) public {
        // sell the stock
    }

    function payDividend() public {
        // pay dividend to shareholders
    }
}