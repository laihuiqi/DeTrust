// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

contract StockContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Stock public stock;

    constructor(BaseContract _base, address _issuer, address _shareHolder, DeTrustToken _wallet, 
        string memory _stockName, string memory _stockCode, uint256 _stockValue, 
        uint256 _shares, uint256 _dividenRate, uint256 _dividenPaymentInterval, 
        uint256 _firstDividenDate, ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {
        
        stock = ContractUtility.Stock(
            _wallet,
            _issuer,
            _shareHolder,
            _stockName,
            _stockCode,
            ContractUtility.SecuritiesState.ISSUED,
            _stockValue,
            _shares,
            _dividenRate,
            _dividenPaymentInterval,
            _firstDividenDate,
            0
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.STOCK,
            _consensus, _dispute, _issuer, _shareHolder);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    function buy() public {
        // buy the stock
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(stock.state == ContractUtility.SecuritiesState.ISSUED, "Stock should be issuing!");
        require(msg.sender == stock.shareholder, "You are not the shareholder!");

        stock.deTrustToken.transfer(stock.issuer, stock.stockValue.mul(stock.shares));
        stock.state = ContractUtility.SecuritiesState.ACTIVE;
    }

    function transfer(address _transferee) public {
        // transfer the stock
        require(msg.sender == stock.shareholder, "You are not the shareholder!");
        
        stock.shareholder = _transferee;
    }

    function payDividen() public {
        // pay dividen to shareholders
        require(stock.state == ContractUtility.SecuritiesState.ACTIVE, "Stock should be active!");
        require(msg.sender == stock.issuer, "Only issuer can pay dividen!");
        require(block.timestamp >= stock.dividenPaymentDate, "dividen payment date has not reached!");

        stock.dividenCount = stock.dividenCount.add(1);
        stock.deTrustToken.approve(stock.shareholder, 
            stock.stockValue.mul(stock.shares).mul(stock.dividenRate).div(100));
        stock.dividenPaymentDate = stock.dividenPaymentDate.add(stock.dividenPaymentInterval);
    }

    function redeemDividen() public {
        // redeem dividen
        require(stock.state == ContractUtility.SecuritiesState.ACTIVE, "Stock should be active!");
        require(msg.sender == stock.shareholder, "You are not the shareholder!");
        require(stock.dividenCount > 0, "No dividen to redeem!");

        stock.dividenCount = 0;
        stock.deTrustToken.transferFrom(stock.issuer, stock.shareholder,
            stock.stockValue.mul(stock.shares).mul(stock.dividenCount).mul(stock.dividenRate).div(100));
    }

    function updateDividenRate(uint256 _newDividenRate) public {
        // update the dividen rate
        require(msg.sender == stock.issuer, "Only issuer can update dividen rate!");
        
        stock.dividenRate = _newDividenRate;
    }

    function updateStockValue(uint256 _newStockValue) public {
        // update the stock value
        require(msg.sender == stock.issuer, "Only issuer can update stock value!");
        
        stock.stockValue = _newStockValue;
    }

    function terminateStockContract() public {
        // terminate the stock contract
        require(msg.sender == stock.issuer, "Only issuer can terminate stock contract!");
        require(stock.state == ContractUtility.SecuritiesState.ACTIVE, "Stock should be active!");

        stock.deTrustToken.transfer(msg.sender, stock.stockValue.mul(stock.shares));
        stock.state = ContractUtility.SecuritiesState.REDEEMED;
        selfdestruct(payable(address(this)));
    }
}