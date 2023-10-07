// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartVoucherContract {
    enum VoucherType { Discount, Gift }

    address payable issuer;
    address payable redeemer;
    address usageAddress;
    string description;
    VoucherType voucherType;
    uint256 value;
    uint256 expiryDate;
    uint256 issuerSignature;
    uint256 redeemerSignature;

    constructor(address payable _issuer, address payable _redeemer, address _usageAddress,
        string memory _description, VoucherType _voucherType, uint256 _value, uint256 _expiryDate) {
        issuer = _issuer;
        redeemer = _redeemer;
        usageAddress = _usageAddress;
        description = _description;
        voucherType = _voucherType;
        value = _value;
        expiryDate = _expiryDate;
    }

    function signContract() public {
        // sign the contract
    }

    function redeem() public {
        // redeem the voucher
    }

    function withdraw() public {
        // withdraw the payment
    }

    function terminate() public {
        // terminate the contract
    }
}