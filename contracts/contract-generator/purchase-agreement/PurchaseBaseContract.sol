// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../DeTrustToken.sol";

contract PurchaseBaseContract {
    using SafeMath for uint256;

    DeTrustToken deTrustToken;
    address payable seller;
    address payable buyer;
    string description;
    uint256 price;
    uint256 paymentDate;
    uint256 deliveryDate;
    uint256 sellerSignature;
    uint256 buyerSignature;
    bool isReceived = false;
    bool isPaid = false;

    constructor(address _seller, address _buyer, DeTrustToken _wallet, string memory _description, uint256 _price, uint256 _insurance, uint256 _paymentDate, uint256 _deliveryDate) {
        deTrustToken = _wallet;
        seller = payable(_seller);
        buyer = payable(_buyer);
        description = _description;
        price = _price;
        paymentDate = _paymentDate;
        deliveryDate = _deliveryDate;
    }

    function pay() public {
        // pay the seller
        require(!isPaid, "Payment has been made!");
        require(paymentDate <= block.timestamp, "Payment date has not reached!");
        require(msg.sender == buyer, "You are not the buyer!");

        deTrustToken.transfer(address(this), price);
        isPaid = true;
    }

    function withdraw() public {
        // withdraw the payment
        require(isPaid, "Payment has not been made!");
        require(msg.sender == seller, "You are not the seller!");
        require(paymentDate <= block.timestamp, "Payment date has not reached!");
        require(isReceived, "Product has not been received!");
        
        deTrustToken.transfer(seller, price);
    }

    function receiveProduct() public {
        require(msg.sender == buyer, "You are not the buyer!");

        isReceived = true;
    }

    function terminate() public {
        // terminate the contract
        require(msg.sender == buyer || msg.sender == seller, "You are not involved in this contract!");
        require((block.timestamp >= deliveryDate && !isReceived) || 
            (block.timestamp >= paymentDate && !isPaid), "Delivery date has not reached!");
        
        if (isPaid) {
            deTrustToken.transfer(buyer, price);
        }
        selfdestruct(payable(address(this)));
    }
}