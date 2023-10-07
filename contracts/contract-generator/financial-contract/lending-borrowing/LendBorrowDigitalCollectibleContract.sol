// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "../../ContractUtility.sol";
import "../FinancialBaseContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendBorrowDigitalCollectibleContract is FinancialBaseContract {
    using SafeMath for uint256;

    mapping(uint256 => LendBorrowDigitalCollectibleContract) public lendBorrowDigitalCollectibleRepo;

    event Lend(address indexed from, address indexed to, uint256 value);
    event Borrow(address indexed from, address indexed to, uint256 value);
    event Repay(address indexed from, address indexed to, uint256 value);
    event Retrieve(address indexed from, address indexed to, uint256 value);

    constructor(address base, address borrower, address lender,  uint256 contractDuration, 
        uint256 creationCost, Type.DisputeType dispute,  uint256 amount, uint256 releaseTime, uint256 releaseAmount) 
        FinancialBaseContract(base, borrower, lender, Type.ContractType.LEND_BORROW_TOKEN, 
            contractDuration, creationCost, dispute, amount, releaseTime, releaseAmount){
    
        lendBorrowDigitalCollectibleRepo[_basicProperties._id] = this;
    
    }

    function getBorrower(uint256 contractId) public view returns (address) {
        return getPromisor(contractId).getUserAddress();
    }

    function lend(uint256 contractId) public payable {
        payable(address(this)).transfer(msg.value);

        emit Lend(msg.sender, address(this), msg.value);
    }

    function borrow(uint256 contractId) public {
        payable(getPromisor(contractId).getUserAddress()).transfer(getAmount());

        emit Borrow(address(this), getPromisor(contractId).getUserAddress(), getAmount());
    }

    function repay(uint256 contractId) public {
        payable(address(this)).transfer(getAmount());

        emit Repay(msg.sender, address(this), getAmount());
    }

    function retrieve(uint256 contractId) public {
        payable(getPromisee(contractId).getUserAddress()).transfer(getAmount());

        emit Retrieve(address(this), getPromisee(contractId).getUserAddress(), getAmount());
    }

    function setInterestRate() public {
        // TODO
    }

}