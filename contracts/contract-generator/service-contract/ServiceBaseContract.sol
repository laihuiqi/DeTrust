// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../ContractUtility.sol";
import "../BaseContract.sol";

/**
 * @title ServiceBaseContract
 * @dev The base contract for service contract
 * 
 * This contract is used for service contracts, include subscription and services.
 */
contract ServiceBaseContract {
    using SafeMath for uint256;
    
    BaseContract public base;
    uint256 contractId;
    ContractUtility.Service public service;
    uint256 cummulativePaymentCount = 0;
    uint256 creationDate;

    event Paid(address _client, address _serviceProvider, uint256 _value);
    event Withdrawn(address _client, address _serviceProvider, uint256 _value);
    event ContractTerminated(address _client, address _serviceProvider);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    constructor(BaseContract _base, ContractUtility.ServiceType _serviceType, address payable _serviceProvider, address payable _client,
        uint256 _contractDuration, string memory _description, uint256 _paymentTerm, uint256 _singlePayment,
        uint256 _firstPaymentDate, ContractUtility.DisputeType _dispute) payable {
        
        service = ContractUtility.Service(
            _serviceType,
            _serviceProvider,
            _client,
            _contractDuration.mul(1 days),
            _description,
            _paymentTerm.mul(1 days),
            _singlePayment,
            _firstPaymentDate
        );

        base = _base;
        creationDate = block.timestamp;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.SERVICE,
            _dispute, _client, _serviceProvider);
    }

    // pay the service provider
    function pay() external payable contractReady {
        require(creationDate + service.contractDuration > block.timestamp &&
            block.timestamp >= service.paymentDate, "Payment date has not reached!");
        require(msg.sender == service.client, "You are not the client!");
        require(msg.value == service.singlePayment, "Payment amount is incorrect!");

        service.paymentDate = service.paymentDate.add(service.paymentTerm);
        cummulativePaymentCount = cummulativePaymentCount.add(1);

        emit Paid(service.client, service.serviceProvider, service.singlePayment);
    }

    // withdraw the payment
    function withdraw() public contractReady {
        require(msg.sender == service.serviceProvider, "You are not the service provider!");
        require(address(this).balance >= service.singlePayment.mul(cummulativePaymentCount), "No payment to withdraw!");

        service.serviceProvider.transfer(service.singlePayment.mul(cummulativePaymentCount));
        cummulativePaymentCount = 0;

        emit Withdrawn(service.client, service.serviceProvider, 
            service.singlePayment.mul(cummulativePaymentCount));
    }

    // terminate the contract
    function terminate() public contractReady  {
        require(msg.sender == service.client || msg.sender == service.serviceProvider, 
            "You are not involved in this contract!");
        require(cummulativePaymentCount == 0, "Payment has not been withdraw!");

        base.completeContract(contractId);

        emit ContractTerminated(service.client, service.serviceProvider);
        selfdestruct(payable(address(this)));
    }

}