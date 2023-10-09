// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../DeTrustToken.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

contract SmartVoucherContract {

    BaseContract public base;
    uint256 contractId;
    ContractUtility.SmartVoucher public smartVoucher;

    constructor(BaseContract _base, address _issuer, address _redeemer, address _usageAddress, string memory _description, 
        DeTrustToken _wallet, ContractUtility.VoucherType _voucherType, uint256 _value, uint256 _expiryDate,
        ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {
        smartVoucher = ContractUtility.SmartVoucher(
            _issuer,
            _redeemer,
            _usageAddress,
            _description,
            _voucherType,
            ContractUtility.VoucherState.ACTIVE,
            _value,
            _expiryDate
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.SMART_VOUCHER,
            _consensus, _dispute, _issuer, _redeemer);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    function redeem() public returns (address, ContractUtility.VoucherType, uint256) {
        // redeem the voucher
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(smartVoucher.state == ContractUtility.VoucherState.ACTIVE, "Voucher should be active!");
        require(msg.sender == smartVoucher.redeemer, "You are not the redeemer!");
        require(block.timestamp <= smartVoucher.expiryDate, "Voucher has expired!");

        smartVoucher.state = ContractUtility.VoucherState.REDEEMED;
        return (smartVoucher.usageAddress, smartVoucher.voucherType, smartVoucher.value);
    }

    function destroy() public {
        // destroy the voucher
        require(smartVoucher.state == ContractUtility.VoucherState.REDEEMED ||
            block.timestamp > smartVoucher.expiryDate, "Voucher is usable!");

        selfdestruct(payable(address(this)));
    }
}