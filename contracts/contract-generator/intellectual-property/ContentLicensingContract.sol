// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LicenseOwningContract.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

/**
 * @title ContentLicensingContract
 * @dev The base contract for content licensing contract
 */
contract ContentLicensingContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.ContentLicensing public contentLicensing;
    bool terminating = false;
    bool isWithdrawn = false;   

    event PayLicense(address _licensee, address _owner, uint256 _value);
    event WithdrawLicense(address _owner, address _licensee, uint256 _value);
    event ExtendLicense(address _licensee, address _owner, uint256 _value);
    event TerminateLicense(address _licensee, address _owner);  
    event ContractTerminated(address _licensee, address _owner);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    constructor(BaseContract _base, address payable _owner, address payable _licensee, 
        address _walletOwner, address _walletLicensee, LicenseOwningContract _license, 
        uint256 _startDate, ContractUtility.DisputeType _dispute) payable {

        require(_owner == _license.getOwner(), 
            "Owner of the license is not the same as the owner of the contract!");
        
        contentLicensing = ContractUtility.ContentLicensing(
            _owner,
            _licensee,
            _license,
            ContractUtility.LicenseState.PENDING,
            _license.getLicensePrice(),
            _startDate,
            _startDate.add(_license.getLicenseRenewalPeriod()));

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.FUTURE,
            _dispute, _owner, _licensee, _walletOwner, _walletLicensee);
    }

    // pay the licensor
    function pay() external payable contractReady {
        require(msg.sender == contentLicensing.licensee, "You are not the licensee!");
        require(contentLicensing.state == ContractUtility.LicenseState.PENDING, "License should be pending!");
        require(msg.value == contentLicensing.price, "Payment amount is incorrect!");

        contentLicensing.state = ContractUtility.LicenseState.ACTIVE;

        emit PayLicense(contentLicensing.licensee, contentLicensing.owner, contentLicensing.price);
    }

    
    function withdraw() public contractReady {
        require(msg.sender == contentLicensing.owner, "You are not the owner!");
        require(address(this).balance >= contentLicensing.price, "No payment to withdraw!");
        require(contentLicensing.state == ContractUtility.LicenseState.ACTIVE, 
            "License should be active!");
        
        contentLicensing.owner.transfer(contentLicensing.price);
        isWithdrawn = true;

        emit WithdrawLicense(contentLicensing.owner, contentLicensing.licensee, contentLicensing.price);
    }

    // extend the license
    function extend() external payable contractReady {
        require(msg.sender == contentLicensing.licensee, "You are not the licensee!");
        require(!terminating, "Contract is terminating!");
        require(block.timestamp >= contentLicensing.endDate.sub(30 days), 
            "Only can be renewed 30 days before the license expires!");
        require(contentLicensing.state == ContractUtility.LicenseState.ACTIVE, "License should be active!");
        require(msg.value == contentLicensing.price, "Payment amount is incorrect!");

        contentLicensing.endDate = contentLicensing.endDate.add(contentLicensing.license.getLicenseRenewalPeriod());
        isWithdrawn = false;

        emit ExtendLicense(contentLicensing.licensee, contentLicensing.owner, contentLicensing.price);
    }

    // terminate the contract
    // disable license renewal
    function terminate() public contractReady {
        require(msg.sender == contentLicensing.owner || msg.sender == contentLicensing.licensee, 
            "You are not involved in this contract!");
        require(!terminating, "Contract is already terminating!");

        terminating = true;

        emit TerminateLicense(contentLicensing.licensee, contentLicensing.owner);
    }

    // destruct the contract
    function destructContract() public contractReady {
        require(block.timestamp > contentLicensing.endDate, "Contract is not terminating!");
        require(isWithdrawn, "Payment has not been withdrawn!");

        base.completeContract(contractId);

        contentLicensing.state = ContractUtility.LicenseState.EXPIRED;

        emit ContractTerminated(contentLicensing.licensee, contentLicensing.owner);
        selfdestruct(payable(address(this)));
    }
}