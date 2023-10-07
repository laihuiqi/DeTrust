// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../DeTrustToken.sol";

contract SmartVoucherContract {
    enum VoucherType { Discount, Gift }
    enum VoucherState { Active, Redeemed }

    DeTrustToken deTrustToken;
    address issuer;
    address redeemer;
    address usageAddress;
    string description;
    VoucherType voucherType;
    VoucherState state = VoucherState.Active;
    uint256 value;
    uint256 expiryDate;

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

    function redeem() public returns (address, VoucherType, uint256) {
        // redeem the voucher
        require(state == VoucherState.Active, "Voucher should be active!");
        require(msg.sender == redeemer, "You are not the redeemer!");
        require(block.timestamp <= expiryDate, "Voucher has expired!");

        state = VoucherState.Redeemed;
        return (usageAddress, voucherType, value);
    }

    function destroy() public {
        // destroy the voucher
        require(state == VoucherState.Redeemed ||
            block.timestamp > expiryDate, "Voucher is usable!");

        selfdestruct(payable(address(this)));
    }
}