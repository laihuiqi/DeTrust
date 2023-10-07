// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ServiceBaseContract {
    enum ServiceType { Freelance, Subscription }

    ServiceType serviceType;
    address serviceProvider;
    address payable client;
    uint256 contractDuration;
    string description;
    uint256 paymentTerm;
    uint256 singlePayment;
    uint256 serviceProviderSignature;
    uint256 clientSignature;

    constructor(ServiceType _serviceType, address _serviceProvider, address payable _client, uint256 _contractDuration, 
        string memory _description, uint256 _paymentTerm, uint256 _singlePayment) {
        serviceType = _serviceType;
        description = _description;
        serviceProvider = _serviceProvider;
        client = _client;
        contractDuration = _contractDuration;
        paymentTerm = _paymentTerm;
        singlePayment = _singlePayment;
    }

    function signContract() public {
        // sign the contract
    }

    function pay() public payable {
        // pay the freelancer
    }

    function withdraw() public {
        // withdraw the payment
    }

    function terminate() public {
        // terminate the contract
    }

}