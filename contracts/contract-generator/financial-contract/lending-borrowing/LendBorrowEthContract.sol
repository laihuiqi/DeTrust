// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "../../ContractUtility.sol";
import "../../BaseContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendBorrowEthContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    address payable escrow = payable(address(this));
    ContractUtility.LendBorrow public lendBorrowEth;
    bool isLended = false;
    bool isBorrowed = false;
    bool isRepaid = false;
    bool isRetrieved = false;

    event Lend(address indexed from, address indexed to, uint256 value);
    event Borrow(address indexed from, address indexed to, uint256 value);
    event Repay(address indexed from, address indexed to, uint256 value);
    event Retrieve(address indexed from, address indexed to, uint256 value);
    event Terminate(address indexed from);
    event SetInterestRate(uint256 value);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    constructor(BaseContract _base, address payable _borrower, address payable _lender, uint256 _contractDuration, 
        uint256 _releaseTime, ContractUtility.DisputeType _dispute,  uint256 _amount, uint256 _interestRate) payable{
    
        lendBorrowEth = ContractUtility.LendBorrow(
            _borrower,
            _lender,
            _contractDuration.mul(1 days),
            _amount,
            _releaseTime,
            _interestRate
            );

        base = _base;
        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.LEND_BORROW_ETH,
            _dispute,_lender, _borrower);
    
    }

    // lender lend the amount
    function lend() public payable contractReady {
        require(msg.sender == lendBorrowEth.lender, "You are not the lender!");
        require(!isLended, "The amount has been released!");
        require(msg.value == lendBorrowEth.amount, "The amount is not correct!");

        isLended = true;

        emit Lend(msg.sender, address(this), msg.value);
    }

    // borrower borrow the amount after the release time
    function borrow() public contractReady {
        require(msg.sender == lendBorrowEth.borrower, "You are not the borrower!");
        require(block.timestamp >= lendBorrowEth.releaseTime, "The release time has not reached!");
        require(isLended, "The amount has not been released!");
        require(address(this).balance >= lendBorrowEth.amount, "The contract does not have enough balance!");

        lendBorrowEth.borrower.transfer(lendBorrowEth.amount);
        isBorrowed = true;

        emit Borrow(address(this), msg.sender, lendBorrowEth.amount);
    }

    // get the amount should be repaid after added with interest
    function getRepayAmount() public view contractReady returns (uint256) {
        return lendBorrowEth.amount.add(lendBorrowEth.amount.mul(
            lendBorrowEth.interestRate).div(100) ** (
            block.timestamp.sub(lendBorrowEth.releaseTime)).div(30 days));
    }

    // borrower repay the amount
    function repay() public payable contractReady {
        require(msg.sender == lendBorrowEth.borrower, "You are not the borrower!");
        require(isBorrowed, "The amount has not been borrowed!");
        require(msg.value == getRepayAmount(), "The repay amount is not correct!");

        isRepaid = true;

        emit Repay(msg.sender, address(this), msg.value);
    }

    // lender retrieve the amount after the borrower repaid
    function retrieve() public contractReady {
        require(msg.sender == lendBorrowEth.lender, "You are not the lender!");
        require(isRepaid, "The amount has not been repaid!");
        require(address(this).balance >= getRepayAmount(), "The contract does not have enough balance!");

        lendBorrowEth.lender.transfer(getRepayAmount());
        isRetrieved = true;

        emit Retrieve(address(this), msg.sender, getRepayAmount());
    }

    // terminate the contract
    function terminate() public contractReady {
        require(isRetrieved || 
            !isBorrowed && block.timestamp > lendBorrowEth.releaseTime.add(lendBorrowEth.contractDuration), 
            "Termination not available!");
        require(msg.sender == lendBorrowEth.lender || msg.sender == lendBorrowEth.borrower, 
            "You are not involved in this contract!");

        if (isLended && !isBorrowed) {
            lendBorrowEth.lender.transfer(lendBorrowEth.amount);
            base.voidContract(contractId);
        } else if (isRetrieved) {
            base.completeContract(contractId);
        } else {
            base.voidContract(contractId);
        }

        emit Terminate(address(this));

        selfdestruct(payable(address(this)));
    }

    // change final interest rate
    function setInterestRate(uint256 _newRate) public contractReady {
        require(msg.sender == lendBorrowEth.lender, "You are not the lender!");
        lendBorrowEth.interestRate = _newRate;

        emit SetInterestRate(_newRate);
    }

}