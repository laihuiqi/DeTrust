// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "../../ContractUtility.sol";
import "../FinancialBaseContract.sol";
import "../../../DeTrustToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendBorrowDTRContract is FinancialBaseContract {
    using SafeMath for uint256;

    DeTrustToken deTrustToken;
    address borrower;
    address lender;
    uint256 contractDuration; 
    uint256 creationCost;
    Type.DisputeType dispute;  
    uint256 amount; 
    uint256 releaseTime; 
    uint256 interestRate = 0;
    bool isLended = false;
    bool isBorrowed = false;
    bool isRepaid = false;
    bool isRetrieved = false;

    mapping(uint256 => LendBorrowDTRContract) public lendBorrowTokenRepo;

    event Lend(address indexed from, address indexed to, uint256 value);
    event Borrow(address indexed from, address indexed to, uint256 value);
    event Repay(address indexed from, address indexed to, uint256 value);
    event Retrieve(address indexed from, address indexed to, uint256 value);

    constructor(address _base, address _borrower, address _lender,  DeTrustToken _wallet, uint256 _contractDuration, 
        uint256 _creationCost, Type.DisputeType _dispute,  uint256 _amount) 
        FinancialBaseContract(_base, _borrower, _lender, Type.ContractType.LEND_BORROW_TOKEN, 
            _contractDuration, _creationCost, _dispute, _amount, block.timestamp, _amount){
    
        deTrustToken = _wallet;
        borrower = _borrower;
        lender = _lender;
        contractDuration = _contractDuration;
        creationCost = _creationCost;
        dispute = _dispute;
        amount = _amount;
        releaseTime = block.timestamp;
        lendBorrowTokenRepo[_basicProperties._id] = this;
    
    }

    function lend() public payable {
        require(!isLended, "The amount has been released!");
        require(msg.sender == lender, "You are not the lender!");

        deTrustToken.transfer(address(this), msg.value);
        isLended = true;

        emit Lend(msg.sender, address(this), msg.value);
    }

    function borrow() public {
        require(isLended, "The amount has not been released!");
        require(msg.sender == borrower, "You are not the borrower!");

        deTrustToken.transfer(borrower, amount);
        isBorrowed = true;
    }

    function repay() public {
        require(isBorrowed, "The amount has not been borrowed!");
        require(msg.sender == borrower, "You are not the borrower!");

        deTrustToken.transfer(address(this),
            amount.add(amount.mul(interestRate).div(100) ** (block.timestamp.sub(releaseTime)).div(30 days)));
        isRepaid = true;

        emit Repay(msg.sender, address(this), getAmount());
    }

    function retrieve() public {
        require(isRepaid, "The amount has not been repaid!");
        require(msg.sender == lender, "You are not the lender!");
        
        deTrustToken.transfer(lender, amount);
        isRetrieved = true;

    }

    function setInterestRate(uint256 _newRate) public {
        interestRate = _newRate;
    }

    function terminate() public {
        require(isRetrieved || 
            !isBorrowed && block.timestamp > releaseTime.add(contractDuration), "The amount has not been repaid!");

        if (!isBorrowed) {
            deTrustToken.transfer(lender, amount);
        }

        selfdestruct(payable(address(this)));
    }

}