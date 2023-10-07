// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimplePaymentContract {
    address payer;
    address payable payee;
    uint256 amount;
    uint256 paymentDate;
    string description;
    uint256 payerSignature;
    uint256 payeeSignature;

    constructor(address _payer, address payable _payee, uint256 _amount, uint256 _paymentDate, string memory _description) {
        payer = _payer;
        payee = _payee;
        amount = _amount;
        paymentDate = _paymentDate;
        description = _description;
    }

    function signContract() public {
        // sign the contract
    }

    function pay() public payable {
        // pay the payee
    }

    function withdraw() public {
        // withdraw the payment
    }

    function terminate() public {
        // terminate the contract
    }
}