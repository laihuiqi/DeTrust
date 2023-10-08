// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../DeTrustToken.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

contract SimplePaymentContract {

    BaseContract public base;
    uint256 contractId;
    ContractUtility.SimplePayment public simplePayment;

    constructor(BaseContract _base, address _payer, address _payee, DeTrustToken _wallet, uint256 _amount, string memory _description,
        ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {
        simplePayment = ContractUtility.SimplePayment(
            _wallet,
            _payer,
            _payee,
            _amount,
            block.timestamp,
            _description,
            false,
            false
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.SIMPLE_PAYMENT,
            _consensus, _dispute, _payer, _payee);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    function pay() public payable {
        // pay the payee
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(!simplePayment.isPaid, "Payment has been made!");
        require(msg.sender == simplePayment.payer, "You are not the payer!");

        simplePayment.deTrustToken.transfer(address(this), simplePayment.amount);
        simplePayment.paymentDate = block.timestamp;
        simplePayment.isPaid = true;
    }

    function withdraw() public {
        // withdraw the payment
        require(simplePayment.isPaid, "Payment has not been made!");
        require(msg.sender == simplePayment.payee, "You are not the payee!");

        simplePayment.deTrustToken.transferFrom(address(this), simplePayment.payee, simplePayment.amount);
        simplePayment.isWithdrawn = true;
    }

    function terminate() public {
        // terminate the contract
        require(msg.sender == simplePayment.payer || msg.sender == simplePayment.payee, 
            "You are not involved in this contract!");

        if (simplePayment.isPaid && !simplePayment.isWithdrawn) {
            simplePayment.deTrustToken.transferFrom(address(this), simplePayment.payer, simplePayment.amount);
        }

        selfdestruct(payable(address(this)));
    }
}