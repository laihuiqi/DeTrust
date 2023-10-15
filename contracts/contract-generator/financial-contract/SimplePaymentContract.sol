// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../ContractUtility.sol";
import "../BaseContract.sol";

/**
 * @title SimplePaymentContract
 * @dev The base contract for simple payment contract
 */
contract SimplePaymentContract {

    BaseContract public base;
    uint256 contractId;
    ContractUtility.SimplePayment public simplePayment;
    bool isPaid = false;
    bool isWithdrawn = false;

    event PaymentMade(address _payer, address _payee, uint256 _amount);
    event PaymentWithdrawn(address _payer, address _payee, uint256 _amount);
    event ContractTerminated(address _payer, address _payee, uint256 _amount);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    constructor(BaseContract _base, address payable _payer, address payable _payee, uint256 _amount, 
        string memory _description, ContractUtility.DisputeType _dispute) payable {
        simplePayment = ContractUtility.SimplePayment(
            _payer,
            _payee,
            _amount,
            block.timestamp,
            _description
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.SIMPLE_PAYMENT,
            _dispute, _payer, _payee);
    }

    // pay the payee
    function pay() external payable contractReady {
        require(msg.sender == simplePayment.payer, "You are not the payer!");
        require(!isPaid, "Payment has been made!");
        require(msg.value == simplePayment.amount, "Incorrect amount!");

        simplePayment.paymentDate = block.timestamp;
        isPaid = true;

        emit PaymentMade(simplePayment.payer, simplePayment.payee, simplePayment.amount);
    }

    // withdraw the payment
    function withdraw() public contractReady {
        require(msg.sender == simplePayment.payee, "You are not the payee!");
        require(isPaid, "Payment has not been made!");
        require(address(this).balance >= simplePayment.amount, "Incorrect amount!");

        simplePayment.payee.transfer(simplePayment.amount);
        isWithdrawn = true;

        emit PaymentWithdrawn(simplePayment.payer, simplePayment.payee, simplePayment.amount);
    }

    // terminate the contract
    function terminate() public contractReady {
        require(msg.sender == simplePayment.payer || msg.sender == simplePayment.payee, 
            "You are not involved in this contract!");

        if (isPaid && !isWithdrawn) {
            require(address(this).balance >= simplePayment.amount, "Incorrect contract balance!");
            simplePayment.payer.transfer(simplePayment.amount);
            base.voidContract(contractId);

        } else if (isPaid) {
            require(isWithdrawn, "Payment has not been withdrawn!");
            base.completeContract(contractId);
        } else {
            base.voidContract(contractId);
        }

        emit ContractTerminated(simplePayment.payer, simplePayment.payee, simplePayment.amount);

        selfdestruct(payable(address(this)));
    }
}