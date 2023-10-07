// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LicenseOwningContract {
    enum LicenseState{ Pending, Approved, Rejected }

    address owner;
    string content;
    LicenseState state;
    bool licenseOfferedToPurchase;
    uint256 licensePrice;
    uint256 lisenceRenewalPeriod;

    mapping(address => uint256) licenseApprovalSignature;

    constructor(address _owner, string memory _content, uint256 _licensePrice, uint256 _lisenceRenewalPeriod) {
        owner = _owner;
        content = _content;
        licensePrice = _licensePrice;
        lisenceRenewalPeriod = _lisenceRenewalPeriod;
    }

    function offerLicenseToPurchase() public {
        // offer the license to purchase
    }

    function approveLicense() public {
        // approve the license
    }

    function rejectLicense() public {
        // reject the license
    }

    function purchaseLicense() public payable {
        // purchase the license
    }

    function renewLicense() public payable {
        // renew the license
    }

    function terminateLicense() public {
        // terminate the license
    }

    function withdraw() public {
        // withdraw the payment
    }

}