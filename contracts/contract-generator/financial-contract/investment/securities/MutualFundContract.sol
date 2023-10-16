// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

/**
 * @title MutualFundContract
 * @dev The base contract for mutual fund contract
 */
contract MutualFundContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Fund public fund;
    uint256 cummulativeYieldValue = 0;
    bool isFundCollected = false;
    bool isFundReturned = false;
    
    event BuyFund(uint256 _value);
    event TransferFund(address _transferee);
    event CollectFund(uint256 _value);
    event PayYield(uint256 _value);
    event RedeemInterest(uint256 _value);
    event ReturnFund(uint256 _value);
    event UpdateYieldRate(uint256 _value);
    event UpdateCommisionRate(uint256 _value);
    event EndFundContract(uint256 _value);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    modifier fundHolderOnly() {
        require(msg.sender == fund.fundHolder, "Only fund holder can call this function!");
        _;
    }

    modifier fundManagerOnly() {
        require(msg.sender == fund.fundManager, "Only fund manager can call this function!");
        _;
    }

    modifier isActive() {
        require(fund.state == ContractUtility.SecuritiesState.ACTIVE, "Fund should be active!");
        _;
    }

    constructor(BaseContract _base, string memory _fundName, string memory _fundDescription, address payable _fundManager, 
        address payable _fundHolder, address _walletFundManager, address _walletFundHolder, 
        uint256 _fundValue, uint256 _fundShare, uint256 _yieldRate, uint256 _interestInterval, 
        uint256 _commisionRate, uint256 _firstInterestDate, ContractUtility.DisputeType _dispute) payable {
    
        fund = ContractUtility.Fund(
            _fundName,
            _fundDescription,
            _fundManager,
            _fundHolder,
            ContractUtility.SecuritiesState.ISSUED,
            _fundValue,
            _fundShare,
            _yieldRate,
            _interestInterval,
            _commisionRate,
            _firstInterestDate
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.FUND,
            _dispute, _fundManager, _fundHolder, _walletFundManager, _walletFundHolder);
    }

    // buy the fund
    function buy() external payable contractReady fundHolderOnly {
        require(fund.state == ContractUtility.SecuritiesState.ISSUED, "Fund should be issuing!");
        require(msg.value == fund.fundValue.mul(fund.fundShares), "Insufficient fund value!");

        fund.state = ContractUtility.SecuritiesState.ACTIVE;

        emit BuyFund(msg.value);
    }

    // sell the fund
    function transfer(address payable _transferee) public contractReady fundHolderOnly isActive {

        fund.fundHolder = _transferee;
        emit TransferFund(_transferee);
    }

    // collect the fund
    function collectFund() public contractReady fundManagerOnly isActive {
        require(!isFundCollected, "Fund has been collected!");

        fund.fundManager.transfer(fund.fundValue.mul(fund.fundShares));
        isFundCollected = true;

        emit CollectFund(fund.fundValue.mul(fund.fundShares));
    }

    // pay interest to the fund holders
    function payYield() external payable contractReady fundManagerOnly isActive {
        require(block.timestamp >= fund.interestPaymentDate, "Interest payment date has not reached!");
        require(msg.value == fund.fundValue.mul(fund.fundShares).mul(fund.yieldRate).mul(100 - fund.commisionRate).div(10000), 
            "Insufficient interest payment!");
    
        fund.interestPaymentDate = fund.interestPaymentDate.add(fund.interestInterval);
        cummulativeYieldValue = cummulativeYieldValue.add(msg.value);

        emit PayYield(msg.value);
    }

    // redeem the interest
    function redeemInterest() public contractReady fundHolderOnly isActive {
        require(cummulativeYieldValue > 0, "No interest to redeem!");
        require(address(this).balance >= cummulativeYieldValue.add(fund.fundValue.mul(fund.fundShares)),
            "Insufficient fund value!");

        fund.fundHolder.transfer(cummulativeYieldValue);
        cummulativeYieldValue = 0;

        emit RedeemInterest(cummulativeYieldValue);
    }

    // return the fund
    function returnFund() external payable contractReady fundManagerOnly isActive {
        require(msg.value == fund.fundValue.mul(fund.fundShares), "Insufficient fund value!");
        require(!isFundReturned, "Fund has been returned!");
        
        isFundReturned = true;

        emit ReturnFund(msg.value);
    }

    // update the yield rate
    function updateYieldRate(uint256 _newYieldRate) public contractReady fundManagerOnly {

        fund.yieldRate = _newYieldRate;

        emit UpdateYieldRate(_newYieldRate);
    }

    // update the commision rate
    function updateCommisionRate(uint256 _newCommisionRate) public contractReady fundManagerOnly {
        require(_newCommisionRate <= 50, "Commision rate should be less than 50!");

        fund.commisionRate = _newCommisionRate;

        emit UpdateCommisionRate(_newCommisionRate);
    }

    // complete the contract
    function endFundContract() public contractReady {
        require(msg.sender == fund.fundHolder, "Only fund holder can terminate the fund contract!");
        require(address(this).balance >= fund.fundValue.mul(fund.fundShares), "Insufficient fund value!");
        require(cummulativeYieldValue == 0, "Please redeem the interest first!");
        require(isFundReturned, "Please wait for the return of fund first!");

        fund.fundHolder.transfer(fund.fundValue.mul(fund.fundShares));
        fund.state = ContractUtility.SecuritiesState.REDEEMED;
        base.completeContract(contractId);
        emit EndFundContract(fund.fundValue.mul(fund.fundShares));
        selfdestruct(payable(address(this)));
    }
}