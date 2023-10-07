// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LicenseOwningContract {
    enum LicenseState{ Pending, Approved, Rejected }

    address owner;
    string content;
    LicenseState state = LicenseState.Pending;
    bool licenseOfferedToPurchase;
    uint256 licensePrice;
    uint256 licenseRenewalPeriod;

    constructor(address _owner, string memory _content, uint256 _licensePrice, uint256 _licenseRenewalPeriod) {
        owner = _owner;
        content = _content;
        licensePrice = _licensePrice;
        licenseRenewalPeriod = _licenseRenewalPeriod;
    }

    function offerLicenseToPurchase(bool offer) public {
        // offer the license to purchase
        require(msg.sender == owner, "You are not the owner of this license!");
        licenseOfferedToPurchase = offer;
    }

    function updateLicensePrice(uint256 _licensePrice) public {
        // update the license price
        require(msg.sender == owner, "You are not the owner of this license!");
        licensePrice = _licensePrice;
    }

    function updateLicenseRenewalPeriod(uint256 _licenseRenewalPeriod) public {
        // update the license renewal period
        require(msg.sender == owner, "You are not the owner of this license!");
        licenseRenewalPeriod = _licenseRenewalPeriod;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getLicenseRenewalPeriod() public view returns (uint256) {
        return licenseRenewalPeriod;
    }

    function getLicensePrice() public view returns (uint256) {
        return licensePrice;
    }
}