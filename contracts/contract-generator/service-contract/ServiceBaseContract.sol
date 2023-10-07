// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../DeTrustToken.sol";

contract ServiceBaseContract {
    using SafeMath for uint256;
    enum ServiceType { Freelance, Subscription }

    DeTrustToken deTrustToken;
    ServiceType serviceType;
    address serviceProvider;
    address payable client;
    uint256 contractDuration;
    string description;
    uint256 paymentTerm;
    uint256 singlePayment;
    uint256 paymentDate;
    uint256 paymentCount = 0;

    constructor(ServiceType _serviceType, address _serviceProvider, address payable _client, DeTrustToken _wallet,
        uint256 _contractDuration, string memory _description, uint256 _paymentTerm, uint256 _singlePayment,
        uint256 _firstPaymentDate) {
        deTrustToken = _wallet;
        serviceType = _serviceType;
        description = _description;
        serviceProvider = _serviceProvider;
        client = _client;
        contractDuration = _contractDuration;
        paymentTerm = _paymentTerm;
        singlePayment = _singlePayment;
        paymentDate = _firstPaymentDate;
    }

    function pay() public {
        // pay the service
        require(block.timestamp >= paymentDate, "Payment date has not reached!");
        require(msg.sender == client, "You are not the client!");

        paymentCount = paymentCount.add(1);
        deTrustToken.approve(serviceProvider, singlePayment);
        paymentDate = paymentDate.add(paymentTerm);
    }

    function withdraw() public {
        // withdraw the payment
        require(msg.sender == serviceProvider, "You are not the service provider!");
        require(paymentCount > 0, "No payment to withdraw!");

        paymentCount = 0;
        deTrustToken.transfer(serviceProvider, singlePayment.mul(paymentCount));
    }

    function terminate() public {
        // terminate the contract
        require(msg.sender == client || msg.sender == serviceProvider, "You are not involved in this contract!");
        require(block.timestamp >= contractDuration, "Contract duration has not reached!");
    
        deTrustToken.transfer(client, singlePayment.mul(paymentCount));
        selfdestruct(payable(address(this)));
    }

}