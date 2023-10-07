// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../DeTrustToken.sol";

contract SimplePaymentContract {
    DeTrustToken deTrustToken;
    address payer;
    address payee;
    uint256 amount;
    uint256 paymentDate;
    string description;
    bool isPaid = false;
    bool isWithdrawn = false;

    constructor(address _payer, address _payee, DeTrustToken _wallet, uint256 _amount, string memory _description) {
        payer = _payer;
        payee = _payee;
        deTrustToken = _wallet;
        amount = _amount;
        description = _description;
    }

    function pay() public payable {
        // pay the payee
        require(!isPaid, "Payment has been made!");
        require(msg.sender == payer, "You are not the payer!");

        deTrustToken.transfer(address(this), amount);
        paymentDate = block.timestamp;
        isPaid = true;
    }

    function withdraw() public {
        // withdraw the payment
        require(isPaid, "Payment has not been made!");
        require(msg.sender == payee, "You are not the payee!");

        deTrustToken.transferFrom(address(this), payee, amount);
        isWithdrawn = true;
    }

    function terminate() public {
        // terminate the contract
        require(msg.sender == payer || msg.sender == payee, "You are not involved in this contract!");

        if (isPaid && !isWithdrawn) {
            deTrustToken.transferFrom(address(this), payer, amount);
        }

        selfdestruct(payable(address(this)));
    }
}