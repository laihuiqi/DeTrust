// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";

contract StockContract {
    using SafeMath for uint256;

    enum StockState { Issued, Active, Terminate }
    DeTrustToken deTrustToken;
    address issuer;
    address shareholder;
    string stockName;
    string stockCode;
    StockState state;
    uint256 stockValue;
    uint256 shares;
    uint256 dividenRate;
    uint256 dividenPaymentInterval;
    uint256 dividenPaymentDate;
    uint256 dividenCount = 0;

    mapping(address => uint256) public shareholders;

    constructor(address _issuer, address _shareHolder, DeTrustToken _wallet, string memory _stockName, string memory _stockCode, uint256 _stockValue, 
        uint256 _shares, uint256 _dividenRate, uint256 _dividenPaymentInterval, uint256 _firstdividenate) {
        deTrustToken = _wallet;
        issuer = _issuer;
        shareholder = _shareHolder;
        stockName = _stockName;
        stockCode = _stockCode;
        state = StockState.Issued;
        stockValue = _stockValue;
        shares = _shares;
        dividenRate = _dividenRate;
        dividenPaymentInterval = _dividenPaymentInterval;
        dividenPaymentDate = _firstdividenate;
    }

    function buy() public {
        // buy the stock
        require(state == StockState.Issued, "Stock should be issuing!");
        require(msg.sender == shareholder, "You are not the shareholder!");

        deTrustToken.transfer(issuer, stockValue.mul(shares));
        state = StockState.Active;
    }

    function transfer(address _transferee) public {
        // transfer the stock
        require(msg.sender == shareholder, "You are not the shareholder!");
        
        shareholder = _transferee;
    }

    function paydividen() public {
        // pay dividen to shareholders
        require(state == StockState.Active, "Stock should be active!");
        require(msg.sender == issuer, "Only issuer can pay dividen!");
        require(block.timestamp >= dividenPaymentDate, "dividen payment date has not reached!");

        dividenCount = dividenCount.add(1);
        deTrustToken.approve(shareholder, stockValue.mul(shares).mul(dividenRate).div(100));
        dividenPaymentDate = dividenPaymentDate.add(dividenPaymentInterval);
    }

    function redeemDividen() public {
        // redeem dividen
        require(state == StockState.Active, "Stock should be active!");
        require(msg.sender == shareholder, "You are not the shareholder!");
        require(dividenCount > 0, "No dividen to redeem!");

        dividenCount = 0;
        deTrustToken.transfer(issuer, stockValue.mul(shares).mul(dividenCount).mul(dividenRate).div(100));
    }

    function updateDividenRate(uint256 _newDividenRate) public {
        // update the dividen rate
        require(msg.sender == issuer, "Only issuer can update dividen rate!");
        
        dividenRate = _newDividenRate;
    }

    function updateStockValue(uint256 _newStockValue) public {
        // update the stock value
        require(msg.sender == issuer, "Only issuer can update stock value!");
        
        stockValue = _newStockValue;
    }

    function terminateStockContract() public {
        // terminate the stock contract
        require(msg.sender == issuer, "Only issuer can terminate stock contract!");
        require(state == StockState.Active, "Stock should be active!");

        deTrustToken.transfer(msg.sender, stockValue.mul(shares));
        state = StockState.Terminate;
        selfdestruct(payable(address(this)));
    }
}