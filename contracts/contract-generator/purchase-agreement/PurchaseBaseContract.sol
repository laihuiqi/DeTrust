// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PurchaseBaseContract {
    address payable seller;
    address payable buyer;
    string description;
    uint256 price;
    uint256 insurance;
    uint256 paymentDate;
    uint256 deliveryDate;
    uint256 sellerSignature;
    uint256 buyerSignature;
    uint256 isReceived;

    constructor(address _seller, address _buyer, string memory _description, uint256 _price, uint256 _insurance, uint256 _paymentDate, uint256 _deliveryDate) {
        seller = payable(_seller);
        buyer = payable(_buyer);
        description = _description;
        price = _price;
        insurance = _insurance;
        paymentDate = _paymentDate;
        deliveryDate = _deliveryDate;
    }

    function signContract() public {
        // sign the contract
    }

    function pay() public payable {
        // pay the seller
    }

    function withdraw() public {
        // withdraw the payment
    }

    function terminate() public {
        // terminate the contract
    }

    function receiveProduct() public {
        // receive the product
    }
}