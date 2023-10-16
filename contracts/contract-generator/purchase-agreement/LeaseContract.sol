// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

/**
 * @title LeaseContract
 * @dev The base contract for lease contract 
 */
contract LeaseContract {
    using SafeMath for uint256;
    
    BaseContract public base;
    uint256 contractId;
    ContractUtility.Lease public lease;
    uint256 cummulativePaymentCount = 0;

    event InitializeRent(uint256 _value);
    event PayRent(uint256 _value);
    event WithdrawRent(address _landlord, address _tenant, uint256 _value);
    event TerminateRent(address _landlord, address _tenant, uint256 _value);
    event ExtendEndDate(address _landlord, address _tenant, uint256 _period);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    modifier isActive() {
        require(lease.state == ContractUtility.LeaseState.ACTIVE, "Lease should be active!");
        _;
    }

    modifier tenantOnly() {
        require(msg.sender == lease.tenant, "Only tenant can call this function!");
        _;
    }

    modifier landlordOnly() {
        require(msg.sender == lease.landlord, "Only landlord can call this function!");
        _;
    }

    modifier checkPaymentDate() {
        require(block.timestamp >= lease.paymentDate, "Payment date has not reached!");
        _;
    }

    constructor(BaseContract _base, address payable _landlord, address payable _tenant, 
        address _walletLandlord, address _walletTenant, string memory _description, 
        uint256 _startDate, uint256 _endDate, uint256 _rent, uint256 _deposit, uint256 _occupancyLimit, 
        uint256 _stampDuty, ContractUtility.DisputeType _dispute) payable {
        
        lease = ContractUtility.Lease(
            _landlord,
            _tenant,
            _description,
            ContractUtility.LeaseState.PENDING,
            _startDate,
            _endDate,
            _startDate.add(30 days),
            _rent,
            _deposit,
            _occupancyLimit,
            _stampDuty
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.LEASE,
            _dispute, _landlord, _tenant, _walletLandlord, _walletTenant);
    }

    // get the payment amount for the first payment
    function getFirstPayment() public view returns (uint256) {
        return lease.rent.add(lease.deposit).add(lease.rent.mul(lease.stampDuty).div(100));
    }

    // initiate the rent and pay deposit
    function initRent() external payable contractReady tenantOnly checkPaymentDate {
        require(lease.state == ContractUtility.LeaseState.PENDING, "Lease should be pending!");
        require(msg.value == getFirstPayment(), "Payment amount is incorrect!");

        lease.paymentDate = lease.paymentDate.add(30 days);
        lease.state = ContractUtility.LeaseState.ACTIVE;
        cummulativePaymentCount = cummulativePaymentCount.add(1);

        emit InitializeRent(msg.value);
    }

    // pay the rent by the tenant
    function pay() external payable contractReady tenantOnly isActive checkPaymentDate {
        require(msg.value == lease.rent, "Payment amount is incorrect!");

        lease.paymentDate = lease.paymentDate.add(30 days);
        cummulativePaymentCount = cummulativePaymentCount.add(1);

        emit PayRent(msg.value);
    }

    // withdraw the payment by the landlord
    function withdraw() public contractReady landlordOnly {
        require(address(this).balance - lease.deposit >= lease.rent.mul(cummulativePaymentCount), "No payment to withdraw!");

        lease.landlord.transfer(lease.rent.mul(cummulativePaymentCount));
        cummulativePaymentCount = 0;

        emit WithdrawRent(lease.landlord, lease.tenant, lease.rent.mul(cummulativePaymentCount));
    }

    // terminate the contract
    function terminate() public contractReady isActive {
        require(msg.sender == lease.tenant || msg.sender == lease.landlord, "You are not involved in this contract!");
        require((block.timestamp >= lease.endDate  ||  block.timestamp > lease.paymentDate.add(90 days)), 
            "Termination condition has not reached!");
        require(cummulativePaymentCount == 0, "Payment has not been withdraw!");

        if (block.timestamp >= lease.endDate) {
            lease.tenant.transfer(lease.deposit);
            base.completeContract(contractId);

        } else {
            base.voidContract(contractId);
        }

        emit TerminateRent(lease.landlord, lease.tenant, lease.rent.mul(cummulativePaymentCount));

        lease.state = ContractUtility.LeaseState.TERMINATED;

        selfdestruct(payable(address(this)));
    }

    // extend the contract end date
    function extendEndDate(uint256 _period) public contractReady landlordOnly isActive() {
        require(block.timestamp < lease.endDate, "Contract has already ended!");

        lease.endDate = lease.endDate.add(_period.mul(30 days));

        emit ExtendEndDate(lease.landlord, lease.tenant, _period);
    }
}