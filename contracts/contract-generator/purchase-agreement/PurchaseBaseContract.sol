// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

/**
 * @title PurchaseBaseContract
 * @dev The base contract for purchase contract 
 */
contract PurchaseBaseContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Purchase public purchase;
    bool isReceived = false;
    bool isPaid = false;
    bool isDelivered = false;
    bool isWithdrawn = false;

    event Paid(address _buyer, address _seller, uint256 _value);
    event Withdrawn(address _buyer, address _seller, uint256 _value);
    event Delivered(address _seller, address _buyer);
    event Received(address _seller, address _buyer);
    event Terminated(address _buyer, address _seller, uint256 _value);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    modifier sellerOnly() {
        require(msg.sender == purchase.seller, "You are not the seller!");
        _;
    }

    modifier buyerOnly() {
        require(msg.sender == purchase.buyer, "You are not the buyer!");
        _;
    }

    modifier checkPaymentDate() {
        require(purchase.paymentDate <= block.timestamp, "Payment date has not reached!");
        _;
    }

    constructor(BaseContract _base, address payable _seller, address payable _buyer, string memory _description, 
        uint256 _price, uint256 _paymentDate, uint256 _deliveryDate, ContractUtility.DisputeType _dispute) payable {
        
        purchase = ContractUtility.Purchase(
            _seller,
            _buyer,
            _description,
            _price,
            _paymentDate,
            _deliveryDate
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.PURCHASE,
            _dispute, _seller, _buyer);
    }

    // pay the seller
    function pay() external payable contractReady buyerOnly checkPaymentDate {
        require(msg.value == purchase.price, "Payment amount is incorrect!");
        require(!isPaid, "Payment has been made!");

        isPaid = true;

        emit Paid(purchase.buyer, purchase.seller, purchase.price);
    }

    // withdraw the payment
    function withdraw() public contractReady sellerOnly checkPaymentDate {
        require(isPaid, "Payment has not been made!");
        require(isReceived, "Product has not been received!");
        require(address(this).balance >= purchase.price, "Incorrect amount!");
        
        payable(purchase.seller).transfer(purchase.price);
        isWithdrawn = true;

        emit Withdrawn(purchase.buyer, purchase.seller, purchase.price);
    }

    // the seller delivers the product
    function deliverProduct() public contractReady buyerOnly {

        isDelivered = true;

        emit Delivered(purchase.seller, purchase.buyer);
    }

    // the buyer receives the product
    function receiveProduct() public contractReady buyerOnly {
        require(isDelivered, "Product has not been delivered!");

        isReceived = true;

        emit Received(purchase.seller, purchase.buyer);
    }

    // terminate the contract, when transaction is not completed
    function terminate() public contractReady {
        require(msg.sender == purchase.buyer || msg.sender == purchase.seller, 
            "You are not involved in this contract!");

        if (isPaid && !isDelivered) {
            require((block.timestamp >= purchase.deliveryDate && !isDelivered) || 
                (block.timestamp >= purchase.paymentDate && !isPaid), "Delivery date has not reached!");

            base.voidContract(contractId);
        
            purchase.buyer.transfer(purchase.price);
        } else if (isPaid && isDelivered) {
            require(isWithdrawn, "Payment has not been withdrawn!");

        } else {
            base.completeContract(contractId);

        }

        emit Terminated(purchase.buyer, purchase.seller, purchase.price);
        selfdestruct(payable(address(this)));
    }
}