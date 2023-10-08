// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../../DeTrustToken.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

contract ServiceBaseContract {
    using SafeMath for uint256;
    
    BaseContract public base;
    uint256 contractId;
    ContractUtility.Service public service;

    constructor(BaseContract _base, ContractUtility.ServiceType _serviceType, address _serviceProvider, address payable _client, DeTrustToken _wallet,
        uint256 _contractDuration, string memory _description, uint256 _paymentTerm, uint256 _singlePayment,
        uint256 _firstPaymentDate, ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {
        
        service = ContractUtility.Service(
            _wallet,
            _serviceType,
            _serviceProvider,
            _client,
            _contractDuration,
            _description,
            _paymentTerm,
            _singlePayment,
            _firstPaymentDate,
            0
        );
        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.SERVICE,
            _consensus, _dispute, _client, _serviceProvider);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    function pay() public {
        // pay the service
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(block.timestamp >= service.paymentDate, "Payment date has not reached!");
        require(msg.sender == service.client, "You are not the client!");

        service.paymentCount = service.paymentCount.add(1);
        service.deTrustToken.approve(service.serviceProvider, service.singlePayment);
        service.paymentDate = service.paymentDate.add(service.paymentTerm);
    }

    function withdraw() public {
        // withdraw the payment
        require(msg.sender == service.serviceProvider, "You are not the service provider!");
        require(service.paymentCount > 0, "No payment to withdraw!");

        service.paymentCount = 0;
        service.deTrustToken.transfer(service.serviceProvider, service.singlePayment.mul(service.paymentCount));
    }

    function terminate() public {
        // terminate the contract
        require(msg.sender == service.client || msg.sender == service.serviceProvider, "You are not involved in this contract!");
        require(block.timestamp >= service.contractDuration, "Contract duration has not reached!");
    
        service.deTrustToken.transfer(service.client, service.singlePayment.mul(service.paymentCount));
        selfdestruct(payable(address(this)));
    }

}