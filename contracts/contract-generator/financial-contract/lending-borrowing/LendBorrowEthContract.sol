// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "../../ContractUtility.sol";
import "../../../DeTrustToken.sol";
import "../../BaseContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendBorrowEthContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    address payable escrow = payable(address(this));
    ContractUtility.LendBorrow public lendBorrowEth;

    event Lend(address indexed from, address indexed to, uint256 value);
    event Borrow(address indexed from, address indexed to, uint256 value);
    event Repay(address indexed from, address indexed to, uint256 value);
    event Retrieve(address indexed from, address indexed to, uint256 value);

    constructor(BaseContract _base, address _borrower, address _lender, DeTrustToken _wallet, uint256 _contractDuration, 
        uint256 _creationCost, ContractUtility.DisputeType _dispute,  uint256 _amount,
        ContractUtility.Consensus _consensus){
    
        lendBorrowEth = ContractUtility.LendBorrow(
            DeTrustToken(address(0)),
            _borrower,
            _lender,
            _contractDuration,
            _creationCost,
            _amount,
            block.timestamp,
            0,
            false,
            false,
            false,
            false);

        base = _base;
        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.LEND_BORROW_ETH,
            _consensus, _dispute,_lender, _borrower);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    
    }

    function lend() public payable {
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(!lendBorrowEth.isLended, "The amount has been released!");
        require(msg.sender == lendBorrowEth.lender, "You are not the lender!");
        require(msg.value == lendBorrowEth.amount, "The amount is not correct!");

        lendBorrowEth.isLended = true;

        emit Lend(msg.sender, address(this), msg.value);
    }

    function borrow() public {
        require(lendBorrowEth.isLended, "The amount has not been released!");
        require(msg.sender == lendBorrowEth.borrower, "You are not the borrower!");

        payable(lendBorrowEth.borrower).transfer(lendBorrowEth.amount);
        lendBorrowEth.isBorrowed = true;
    }

    function repay() public payable {
        require(lendBorrowEth.isBorrowed, "The amount has not been borrowed!");
        require(msg.sender == lendBorrowEth.borrower, "You are not the borrower!");
        
        uint256 amountToRepay = lendBorrowEth.amount.add(lendBorrowEth.amount.mul(
            lendBorrowEth.interestRate).div(100) ** (
            block.timestamp.sub(lendBorrowEth.releaseTime)).div(30 days));

        require(msg.value == amountToRepay, "The amount is not correct!");

        lendBorrowEth.isRepaid = true;
    }

    function retrieve() public {
        require(lendBorrowEth.isRepaid, "The amount has not been repaid!");
        require(msg.sender == lendBorrowEth.lender, "You are not the lender!");

        payable(lendBorrowEth.lender).transfer(lendBorrowEth.amount);
        lendBorrowEth.isRetrieved = true;
    }

    function terminate() public {
        require(lendBorrowEth.isRetrieved || 
            !lendBorrowEth.isBorrowed && block.timestamp > lendBorrowEth.releaseTime.add(lendBorrowEth.contractDuration), 
            "The amount has not been repaid!");

        if (!lendBorrowEth.isBorrowed) {
            payable(lendBorrowEth.lender).transfer(lendBorrowEth.amount);
        }

        selfdestruct(payable(address(this)));
    }

    function setInterestRate(uint256 _newRate) public {
        require(msg.sender == lendBorrowEth.lender, "You are not the lender!");
        lendBorrowEth.interestRate = _newRate;
    }

}