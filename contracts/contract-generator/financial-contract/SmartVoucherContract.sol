// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../ContractUtility.sol";
import "../BaseContract.sol";

/**
 * @title SmartVoucherContract
 * @dev The base contract for smart voucher contract
 */
contract SmartVoucherContract {

    BaseContract public base;
    uint256 contractId;
    ContractUtility.SmartVoucher public smartVoucher;

    event ContractTerminated(address _issuer, address _redeemer, uint256 _value);
    event ContractRedeemed(address _issuer, address _redeemer, uint256 _value);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    constructor(BaseContract _base, address _issuer, address _redeemer, address _usageAddress, 
        address _walletIssuer, address _walletRedeemer, string memory _description, 
        ContractUtility.VoucherType _voucherType, uint256 _value, uint256 _expiryDate,
        ContractUtility.DisputeType _dispute) payable {
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
            _dispute, _issuer, _redeemer, _walletIssuer, _walletRedeemer);
    }

    // redeem the voucher
    function redeem() public contractReady returns (address, ContractUtility.VoucherType, uint256) {
        require(msg.sender == smartVoucher.redeemer, "You are not the redeemer!");
        require(smartVoucher.state == ContractUtility.VoucherState.ACTIVE, "Voucher should be active!");
        require(block.timestamp <= smartVoucher.expiryDate, "Voucher has expired!");

        smartVoucher.state = ContractUtility.VoucherState.REDEEMED;

        emit ContractTerminated(smartVoucher.issuer, smartVoucher.redeemer, smartVoucher.value);
        return (smartVoucher.usageAddress, smartVoucher.voucherType, smartVoucher.value);
    }

    // destroy the voucher
    function destroy() public contractReady {
        require(smartVoucher.state == ContractUtility.VoucherState.REDEEMED ||
            block.timestamp > smartVoucher.expiryDate, "Voucher is usable!");

        base.completeContract(contractId);

        emit ContractTerminated(smartVoucher.issuer, smartVoucher.redeemer, smartVoucher.value);

        selfdestruct(payable(address(this)));
    }
}