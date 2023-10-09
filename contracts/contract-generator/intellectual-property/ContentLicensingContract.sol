// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../DeTrustToken.sol";
import "./LicenseOwningContract.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

contract ContentLicensingContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.ContentLicensing public contentLicensing;

    constructor(BaseContract _base, address _owner, address _licensee, DeTrustToken _wallet, LicenseOwningContract _license, 
        uint256 _startDate, ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {
        require(_owner == _license.getOwner(), "Owner of the license is not the same as the owner of the contract!");
        
        contentLicensing = ContractUtility.ContentLicensing(
            _wallet, 
            _owner,
            _licensee,
            _license,
            ContractUtility.LicenseState.PENDING,
            _license.getLicensePrice(),
            _startDate,
            _startDate.add(_license.getLicenseRenewalPeriod()),
            0,
            false);

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.FUTURE,
            _consensus, _dispute, _owner, _licensee);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    function pay() public {
        // pay the licensor
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(contentLicensing.state == ContractUtility.LicenseState.PENDING, "License should be pending!");
        require(msg.sender == contentLicensing.licensee, "You are not the licensee!");

        contentLicensing.payment = contentLicensing.payment.add(1);
        contentLicensing.deTrustToken.transfer(address(this), contentLicensing.price);
        contentLicensing.state = ContractUtility.LicenseState.ACTIVE;
    }

    function withdraw() public {
        // withdraw the payment
        require(contentLicensing.payment > 0, "No payment to withdraw!");
        require(contentLicensing.state == ContractUtility.LicenseState.ACTIVE, 
            "License should be active!");
        require(msg.sender == contentLicensing.owner, "You are not the owner!");

        contentLicensing.deTrustToken.transfer(contentLicensing.owner, contentLicensing.price.mul(contentLicensing.payment));
        contentLicensing.payment = 0;
    }

    function extend() public {
        // extend the license
        require(!contentLicensing.terminating, "Contract is terminating!");
        require(block.timestamp >= contentLicensing.endDate.sub(30 days), 
            "Only can be renewed 30 days before the license expires!");
        require(contentLicensing.state == ContractUtility.LicenseState.ACTIVE, "License should be active!");
        require(msg.sender == contentLicensing.licensee, "You are not the licensee!");

        contentLicensing.payment = contentLicensing.payment.add(1);
        contentLicensing.deTrustToken.transfer(address(this), contentLicensing.price);
        contentLicensing.endDate = contentLicensing.endDate.add(contentLicensing.license.getLicenseRenewalPeriod());
    }

    function terminate() public {
        // terminate the contract
        require(msg.sender == contentLicensing.owner || msg.sender == contentLicensing.licensee, 
            "You are not involved in this contract!");
        require(!contentLicensing.terminating, "Contract is already terminating!");

        contentLicensing.terminating = true;
    }

    function endContract() public {
        require(block.timestamp > contentLicensing.endDate, "Contract is not terminating!");

        contentLicensing.state = ContractUtility.LicenseState.EXPIRED;
        selfdestruct(payable(address(this)));
    }
}