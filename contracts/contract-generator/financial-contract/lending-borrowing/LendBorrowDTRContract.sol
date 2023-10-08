// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "../../ContractUtility.sol";
import "../../../DeTrustToken.sol";
import "../../BaseContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendBorrowDTRContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.LendBorrow public lendBorrowDtr;

    event Lend(address indexed from, address indexed to, uint256 value);
    event Borrow(address indexed from, address indexed to, uint256 value);
    event Repay(address indexed from, address indexed to, uint256 value);
    event Retrieve(address indexed from, address indexed to, uint256 value);

    constructor(BaseContract _base, address _borrower, address _lender,  DeTrustToken _wallet, uint256 _contractDuration, 
        uint256 _creationCost, ContractUtility.DisputeType _dispute,  uint256 _amount, ContractUtility.Consensus _consensus) {
    
        lendBorrowDtr = ContractUtility.LendBorrow(
            _wallet,
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

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.LEND_BORROW_DTR,
            _consensus, _dispute, _lender, _borrower);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    
    }

    function lend() public payable {
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(!lendBorrowDtr.isLended, "The amount has been released!");
        require(msg.sender == lendBorrowDtr.lender, "You are not the lender!");

        lendBorrowDtr.deTrustToken.transfer(address(this), msg.value);
        lendBorrowDtr.isLended = true;

        emit Lend(msg.sender, address(this), msg.value);
    }

    function borrow() public {
        require(lendBorrowDtr.isLended, "The amount has not been released!");
        require(msg.sender == lendBorrowDtr.borrower, "You are not the borrower!");

        lendBorrowDtr.deTrustToken.transferFrom(address(this), lendBorrowDtr.borrower, lendBorrowDtr.amount);
        lendBorrowDtr.isBorrowed = true;
    }

    function repay() public {
        require(lendBorrowDtr.isBorrowed, "The amount has not been borrowed!");
        require(msg.sender == lendBorrowDtr.borrower, "You are not the borrower!");

        lendBorrowDtr.deTrustToken.transfer(address(this),
            lendBorrowDtr.amount.add(lendBorrowDtr.amount.mul(
                lendBorrowDtr.interestRate).div(100) ** (block.timestamp.sub(
                    lendBorrowDtr.releaseTime)).div(30 days)));
        lendBorrowDtr.isRepaid = true;
    }

    function retrieve() public {
        require(lendBorrowDtr.isRepaid, "The amount has not been repaid!");
        require(msg.sender == lendBorrowDtr.lender, "You are not the lender!");
        
        lendBorrowDtr.deTrustToken.transferFrom(address(this), lendBorrowDtr.lender, lendBorrowDtr.amount);
        lendBorrowDtr.isRetrieved = true;

    }

    function setInterestRate(uint256 _newRate) public {
        lendBorrowDtr.interestRate = _newRate;
    }

    function terminate() public {
        require(lendBorrowDtr.isRetrieved || 
            !lendBorrowDtr.isBorrowed && block.timestamp > lendBorrowDtr.releaseTime.add(lendBorrowDtr.contractDuration),
            "The amount has not been repaid!");

        if (!lendBorrowDtr.isBorrowed) {
            lendBorrowDtr.deTrustToken.transferFrom(address(this), lendBorrowDtr.lender, lendBorrowDtr.amount);
        }

        selfdestruct(payable(address(this)));
    }

}