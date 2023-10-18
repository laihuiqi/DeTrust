// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

/**
 * @title StockContract
 * @dev The base contract for stock contract
 */
contract StockContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Stock public stock;
    uint256 dividenValue = 0;
    bool isFundCollected = false;
    bool isFundReturned = false;

    event BuyStock(uint256 _value);
    event TransferStock(address _transferee);
    event CollectFund();
    event PayDividen(uint256 _value);
    event RedeemDividen();
    event ReturnFund();
    event UpdateDividenRate(uint256 _value);
    event UpdateStockValue(uint256 _value);
    event EndStockContract(uint256 _value);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    modifier issuerOnly() {
        require(msg.sender == stock.issuer, "Only issuer can call this function!");
        _;
    }

    modifier shareholderOnly() {
        require(msg.sender == stock.shareholder, "Only shareholder can call this function!");
        _;
    }

    modifier isActive() {
        require(stock.state == ContractUtility.SecuritiesState.ACTIVE, "Stock should be active!");
        _;
    }

    constructor(BaseContract _base, address payable _issuer, address payable _shareHolder, 
        address _walletIssuer, address _walletShareHoler, string memory _stockName, 
        string memory _stockCode, uint256 _stockValue, uint256 _shares, uint256 _dividenRate, 
        uint256 _dividenPaymentInterval, uint256 _firstDividenDate, ContractUtility.DisputeType _dispute) payable {
        
        stock = ContractUtility.Stock(
            _issuer,
            _shareHolder,
            _stockName,
            _stockCode,
            ContractUtility.SecuritiesState.ISSUED,
            _stockValue,
            _shares,
            _dividenRate,
            _dividenPaymentInterval,
            _firstDividenDate
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.STOCK,
            _dispute, _issuer, _shareHolder, _walletIssuer, _walletShareHoler);
    }

    // buy the stock
    function buy() external payable contractReady shareholderOnly {
        require(stock.state == ContractUtility.SecuritiesState.ISSUED, "Stock should be issuing!");
        require(msg.value == stock.stockValue.mul(stock.shares), "The amount is not correct!");

        stock.state = ContractUtility.SecuritiesState.ACTIVE;

        emit BuyStock(msg.value);
    }

    // transfer the stock
    function transfer(address payable _transferee) public contractReady {
        require(msg.sender == stock.shareholder, "You are not the shareholder!");
        
        stock.shareholder = _transferee;

        emit TransferStock(_transferee);
    }

    // collect fund from shareholders
    function collectFund() public contractReady issuerOnly isActive {
        require(!isFundCollected, "Fund has been collected!");

        stock.issuer.transfer(stock.stockValue.mul(stock.shares));
        isFundCollected = true;

        emit CollectFund();
    }

    // pay dividen to shareholders
    function payDividen() external payable contractReady issuerOnly isActive {
        require(block.timestamp >= stock.dividenPaymentDate, "dividen payment date has not reached!");
        require(msg.value == stock.stockValue.mul(stock.shares).mul(stock.dividenRate).div(100), 
            "The amount is not correct!");

        dividenValue = dividenValue.add(msg.value);
        stock.dividenPaymentDate = stock.dividenPaymentDate.add(stock.dividenPaymentInterval);

        emit PayDividen(msg.value);
    }

    // shareholder redeems dividen
    function redeemDividen() public contractReady shareholderOnly isActive {
        require(dividenValue > 0, "No dividen to redeem!");
        require(address(this).balance >= dividenValue.add(stock.stockValue.mul(stock.shares)), 
            "The contract does not have enough balance!");

        stock.shareholder.transfer(dividenValue);
        dividenValue = 0;

        emit RedeemDividen();
    }

    // return fund to shareholder
    function returnFund() external payable contractReady issuerOnly isActive {
        require(msg.value == stock.stockValue.mul(stock.shares), "The amount is not correct!");
        require(!isFundReturned, "Fund has been returned!");

        isFundReturned = true;

        emit ReturnFund();
    }

    // update the dividen rate
    function updateDividenRate(uint256 _newDividenRate) public contractReady issuerOnly {
        
        stock.dividenRate = _newDividenRate;

        emit UpdateDividenRate(_newDividenRate);
    }

    // update the stock value
    function updateStockValue(uint256 _newStockValue) public contractReady issuerOnly {
        
        stock.stockValue = _newStockValue;

        emit UpdateStockValue(_newStockValue);
    }

    // terminate the stock contract
    function endStockContract() public contractReady isActive {
        require(msg.sender == stock.issuer || msg.sender == stock.shareholder, "You are not involved in this contract!");
        require(dividenValue == 0, "Dividen should be redeemed first!");
        require(isFundReturned, "Please wait for the return of fund first!");
        require(address(this).balance >= stock.stockValue.mul(stock.shares), "Insufficient fund value!");

        stock.shareholder.transfer(stock.stockValue.mul(stock.shares));
        stock.state = ContractUtility.SecuritiesState.REDEEMED;
        base.completeContract(contractId);
        emit EndStockContract(stock.stockValue.mul(stock.shares));
        selfdestruct(payable(address(this)));
    }
}