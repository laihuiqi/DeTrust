// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../DeTrustToken.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

contract LeaseContract {
    using SafeMath for uint256;
    
    BaseContract public base;
    uint256 contractId;
    ContractUtility.Lease public lease;

    constructor(BaseContract _base, address _landlord, address _tenant, DeTrustToken _wallet, string memory _description, 
        uint256 _startDate, uint256 _endDate, uint256 _rent, uint256 _deposit, uint256 _occupancyLimit, 
        uint256 _stampDuty, ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {
        
        lease = ContractUtility.Lease(
            _wallet,
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
            _stampDuty,
            0
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.LEASE,
            _consensus, _dispute, _landlord, _tenant);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }


    function initRent() public {
        // pay the rent
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(lease.state == ContractUtility.LeaseState.PENDING, "Lease should be pending!");
        require(msg.sender == lease.tenant, "You are not the tenant!");
        require(block.timestamp >= lease.paymentDate, "Payment date has not reached!");

        lease.deTrustToken.transfer(lease.landlord, 
            lease.rent.add(lease.deposit).add(lease.rent.mul(lease.stampDuty).div(100)));
        lease.paymentDate = lease.paymentDate.add(30 days);
        lease.state = ContractUtility.LeaseState.ACTIVE;
    }

    function pay() public {
        // pay the rent
        require(lease.state == ContractUtility.LeaseState.ACTIVE, "Lease should be active!");
        require(msg.sender == lease.tenant, "You are not the tenant!");
        require(block.timestamp >= lease.paymentDate, "Payment date has not reached!");

        lease.deTrustToken.transfer(address(this), lease.rent);
        lease.paymentDate = lease.paymentDate.add(30 days);
    }

    function withdraw() public {
        // withdraw the payment
        require(msg.sender == lease.landlord, "You are not the landlord!");
        require(lease.paymentCount > 0, "No payment to withdraw!");

        lease.paymentCount = 0;
        lease.deTrustToken.transfer(lease.landlord, lease.rent.mul(lease.paymentCount));
    }

    function terminate() public {
        // terminate the contract
        require(lease.state == ContractUtility.LeaseState.ACTIVE, "Lease should be active!");
        require(msg.sender == lease.tenant || msg.sender == lease.landlord, "You are not involved in this contract!");
        require(lease.paymentCount == 0 && (block.timestamp >= lease.endDate  || 
            block.timestamp > lease.paymentDate.add(90 days)), 
            "Termination condition has not reached!");

        if (block.timestamp >= lease.endDate) {
            lease.deTrustToken.transfer(lease.tenant, lease.deposit);
        } 

        lease.state = ContractUtility.LeaseState.TERMINATED;

        selfdestruct(payable(address(this)));
    }

    function extendEndDate(uint256 _period) public {
        // extend the end date
        require(lease.state == ContractUtility.LeaseState.ACTIVE, "Lease should be active!");
        require(msg.sender == lease.landlord, "You are not the landlord!");
        require(block.timestamp < lease.endDate, "Contract has already ended!");

        lease.endDate = lease.endDate.add(_period.mul(30 days));
    }
}