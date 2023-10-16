// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

contract FutureContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Future public future;
    uint256 currentAmount = 0;
    bool isPaid = false;
    bool isReceived = false;

    event ContractInit();
    event IncreaseBalance(uint256 value);
    event Settle();
    event VerifyReceive();
    event RevertFuture();

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    modifier sellerOnly() {
        require(msg.sender == future.seller, "You are not the seller!");
        _;
    }

    modifier buyerOnly() {
        require(msg.sender == future.buyer, "You are not the buyer!");
        _;
    }

    modifier isActive() {
        require(future.state == ContractUtility.DerivativeState.ACTIVE, "Future contract is not active!");
        _;
    }

    modifier deliveryDatePassed() {
        require(block.timestamp >= future.deliveryDate, "Delivery date has not reached!");
        future.state = ContractUtility.DerivativeState.EXPIRED;
        _;
    }

    constructor(BaseContract _base, address payable _seller, address payable _buyer, 
        address _walletSeller, address _walletBuyer, string memory _assetType, uint256 _assetCode, 
        uint256 _quantity, uint256 _deliveryDays, uint256 _futurePrice, string memory _description, 
        ContractUtility.DisputeType _dispute) payable {

        future = ContractUtility.Future(
            _seller,
            _buyer, 
            ContractUtility.DerivativeState.PENDING,
            _assetType, 
            _assetCode,
            _quantity, 
            block.timestamp.add(_deliveryDays.mul(1 days)), 
            _futurePrice, 
            _futurePrice.div(2), 
            _description);

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.FUTURE,
            _dispute, _seller, _buyer, _walletSeller, _walletBuyer);

    }

    // buyer verify the future contract
    function buyerInit() external payable contractReady buyerOnly {
        require(future.state == ContractUtility.DerivativeState.PENDING, "Future contract has been verified!");
        require(msg.value >= future.margin.mul(future.quantity), "Future premium is not correct!");

        future.state = ContractUtility.DerivativeState.ACTIVE;
        currentAmount = currentAmount.add(msg.value);
        
        emit ContractInit();
    }
    
    // add balance to contract
    function increaseBalance() external payable contractReady buyerOnly isActive {
        require(currentAmount.add(msg.value) <= future.futurePrice.mul(future.quantity), "Payment exceeds limit");

        currentAmount = currentAmount.add(msg.value);

        emit IncreaseBalance(msg.value);
    }

    // pay the seller
    function settle() public contractReady buyerOnly isActive deliveryDatePassed {
        require(currentAmount == future.futurePrice.mul(future.quantity), "Payment is not correct!");

        future.seller.transfer(future.futurePrice.mul(future.quantity));
        isPaid = true;
        currentAmount = 0;

        emit Settle();
    }

    // buyer verify receiving the asset
    function verifyReceive() public contractReady buyerOnly isActive deliveryDatePassed {
        require(isPaid, "Payment has not been made!");

        isReceived = true;
        base.completeContract(contractId);
        emit VerifyReceive();
        selfdestruct(payable(address(this)));
    }

    // revert the future contract
    function revertFuture() internal isActive {
        require(msg.sender == future.seller || msg.sender == future.buyer, "You are not involved in this contract!");
        require(address(this).balance >= currentAmount, "Balance is not enough to revert!");
        require(block.timestamp < future.deliveryDate, "Delivery date has passed!");

        future.buyer.transfer(currentAmount);
        base.voidContract(contractId);
        emit RevertFuture();
        selfdestruct(payable(address(this)));
    }

}