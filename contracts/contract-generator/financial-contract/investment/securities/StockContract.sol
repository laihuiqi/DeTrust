// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";

contract StockContract {
    using SafeMath for uint256;

    enum StockState { Issued, Active }
    DeTrustToken deTrustToken;
    address issuer;
    address shareholder;
    string stockName;
    string stockCode;
    StockState state;
    uint256 stockValue;
    uint256 shares;
    uint256 dividendRate;
    uint256 dividendPaymentInterval;
    uint256 dividendPaymentDate;

    mapping(address => uint256) public shareholders;

    constructor(address _issuer, address _shareHolder, DeTrustToken _wallet, string memory _stockName, string memory _stockCode, uint256 _stockValue, 
        uint256 _shares, uint256 _dividendRate, uint256 _dividendPaymentInterval, uint256 _firstDividenDate) {
        deTrustToken = _wallet;
        issuer = _issuer;
        shareholder = _shareHolder;
        stockName = _stockName;
        stockCode = _stockCode;
        state = StockState.Issued;
        stockValue = _stockValue;
        shares = _shares;
        dividendRate = _dividendRate;
        dividendPaymentInterval = _dividendPaymentInterval;
        dividendPaymentDate = _firstDividenDate;
    }

    function buy() public {
        // buy the stock
        require(state == StockState.Issued, "Stock should be issuing!");
        deTrustToken.transfer(issuer, stockValue.mul(shares));
        state = StockState.Active;
    }

    function transfer(address _transferee) public {
        // transfer the stock
        require(msg.sender == shareholder, "You are not the shareholder!");
        shareholder = _transferee;
    }

    function payDividend() public {
        // pay dividend to shareholders
        require(state == StockState.Active, "Stock should be active!");
        require(msg.sender == issuer, "Only issuer can pay dividend!");
        require(block.timestamp >= dividendPaymentDate, "Dividend payment date has not reached!");

        deTrustToken.transfer(shareholder, stockValue.mul(shares).mul(dividendRate).div(100));
        dividendPaymentDate = dividendPaymentDate.add(dividendPaymentInterval);
    }

    function updateDividenRate(uint256 _newDividendRate) public {
        // update the dividend rate
        require(msg.sender == issuer, "Only issuer can update dividend rate!");
        dividendRate = _newDividendRate;
    }

    function updateStockValue(uint256 _newStockValue) public {
        // update the stock value
        require(msg.sender == issuer, "Only issuer can update stock value!");
        stockValue = _newStockValue;
    }
}