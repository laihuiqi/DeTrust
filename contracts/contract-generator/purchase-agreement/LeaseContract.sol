// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../DeTrustToken.sol";

contract LeaseContract {
    using SafeMath for uint256;
    enum LeaseState { Pending, Active, Terminated }

    DeTrustToken deTrustToken;
    address landlord;
    address tenant;
    string description;
    LeaseState state = LeaseState.Pending;
    uint256 startDate;
    uint256 endDate;
    uint256 paymentDate;
    uint256 rent;
    uint256 deposit;
    uint256 occupancyLimit;
    uint256 stampDuty;
    uint256 paymentCount = 0;

    constructor(address _landlord, address _tenant, DeTrustToken _wallet, string memory _description, uint256 _startDate, uint256 _endDate, uint256 _rent, uint256 _deposit, uint256 _occupancyLimit, uint256 _stampDuty) {
        landlord = _landlord;
        tenant = _tenant;
        deTrustToken = _wallet;
        description = _description;
        startDate = _startDate;
        endDate = _endDate;
        rent = _rent;
        deposit = _deposit;
        occupancyLimit = _occupancyLimit;
        stampDuty = _stampDuty;
        paymentDate = startDate;
    }

    function initRent() public {
        // pay the rent
        require(state == LeaseState.Pending, "Lease should be pending!");
        require(msg.sender == tenant, "You are not the tenant!");
        require(block.timestamp >= paymentDate, "Payment date has not reached!");

        deTrustToken.transfer(landlord, rent.add(deposit).add(rent.mul(stampDuty).div(100)));
        paymentDate = paymentDate.add(30 days);
        state = LeaseState.Active;
    }

    function pay() public {
        // pay the rent
        require(state == LeaseState.Active, "Lease should be active!");
        require(msg.sender == tenant, "You are not the tenant!");
        require(block.timestamp >= paymentDate, "Payment date has not reached!");

        deTrustToken.transfer(address(this), rent);
        paymentDate = paymentDate.add(30 days);
    }

    function withdraw() public {
        // withdraw the payment
        require(msg.sender == landlord, "You are not the landlord!");
        require(paymentCount > 0, "No payment to withdraw!");

        paymentCount = 0;
        deTrustToken.transfer(landlord, rent.mul(paymentCount));
    }

    function terminate() public {
        // terminate the contract
        require(state == LeaseState.Active, "Lease should be active!");
        require(msg.sender == tenant || msg.sender == landlord, "You are not involved in this contract!");
        require(paymentCount == 0 && (block.timestamp >= endDate  || 
            block.timestamp > paymentDate.add(90 days)), 
            "Termination condition has not reached!");

        if (block.timestamp >= endDate) {
            deTrustToken.transfer(tenant, deposit);
        } 

        state = LeaseState.Terminated;

        selfdestruct(payable(address(this)));
    }

    function extendEndDate(uint256 _period) public {
        // extend the end date
        require(state == LeaseState.Active, "Lease should be active!");
        require(msg.sender == landlord, "You are not the landlord!");
        require(block.timestamp < endDate, "Contract has already ended!");

        endDate = endDate.add(_period.mul(30 days));
    }
}