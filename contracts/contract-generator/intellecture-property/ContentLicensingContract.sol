// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../DeTrustToken.sol";
import "./LicenseOwningContract.sol";

contract ContentLicensingContract {
    using SafeMath for uint256;

    enum LicenseState{ Pending, Active, Expired }

    DeTrustToken deTrustToken;
    address owner;
    address licensee;
    LicenseOwningContract license;
    LicenseState state = LicenseState.Pending;
    uint256 price;
    uint256 startDate;
    uint256 endDate;
    uint256 payment = 0;
    bool terminating = false;

    constructor(address _owner, address _licensee, DeTrustToken _wallet, LicenseOwningContract _license, uint256 _startDate) {
        require(_owner == _license.getOwner(), "Owner of the license is not the same as the owner of the contract!");
        owner = _owner;
        licensee = _licensee;
        license = _license;
        deTrustToken = _wallet;
        startDate = _startDate;
        price = license.getLicensePrice();
        endDate = startDate.add(license.getLicenseRenewalPeriod());
    }

    function pay() public {
        // pay the licensor
        require(state == LicenseState.Pending, "License should be pending!");
        require(msg.sender == licensee, "You are not the licensee!");

        payment = payment.add(1);
        deTrustToken.transfer(address(this), price);
        state = LicenseState.Active;
    }

    function withdraw() public {
        // withdraw the payment
        require(payment > 0, "No payment to withdraw!");
        require(state == LicenseState.Active, "License should be active!");
        require(msg.sender == owner, "You are not the owner!");

        deTrustToken.transfer(owner, price.mul(payment));
        payment = 0;
    }

    function extend() public {
        // extend the license
        require(!terminating, "Contract is terminating!");
        require(block.timestamp >= endDate.sub(30 days), "Only can be renewed 30 days before the license expires!");
        require(state == LicenseState.Active, "License should be active!");
        require(msg.sender == licensee, "You are not the licensee!");

        payment = payment.add(1);
        deTrustToken.transfer(address(this), price);
        endDate = endDate.add(license.getLicenseRenewalPeriod());
    }

    function terminate() public {
        // terminate the contract
        require(msg.sender == owner || msg.sender == licensee, "You are not involved in this contract!");
        require(!terminating, "Contract is already terminating!");

        terminating = true;
    }

    function endContract() public {
        require(block.timestamp > endDate, "Contract is not terminating!");
        selfdestruct(payable(address(this)));
    }
}