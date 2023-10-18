// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

/**
 * @title StockContract
 * @dev The base contract for stock contract
 */
contract BondContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Bond public bond;
    uint256 cummulativeCouponValue = 0;
    bool isRedemptionReady = false;
    bool isFundCollected = false;

    event BuyBond(uint256 _value);
    event TransferBond(address _transferee);
    event CollectFund(uint256 _value);
    event PayCoupon(uint256 _value);
    event PayRedemption(uint256 _value);
    event RedeemCoupon(uint256 _value);
    event EndBond(uint256 _value);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    modifier issuerOnly() {
        require(msg.sender == bond.issuer, "Only issuer can call this function!");
        _;
    }

    modifier bondHolderOnly() {
        require(msg.sender == bond.owner, "Only bond holder can call this function!");
        _;
    }

    modifier isActive() {
        require(bond.state == ContractUtility.SecuritiesState.ACTIVE, "Bond should be active!");
        _;
    }

    constructor(BaseContract _base, address payable _issuer, address payable _owner, 
        address _walletIssuer, address _walletOwner, string memory _bondName, 
        string memory _bondCode, uint256 _quantity, uint256 _issueDate, uint256 _maturity, 
        uint256 _couponRate, uint256 _couponPaymentInterval, uint256 _faceValue, 
        uint256 _redemptionValue, ContractUtility.DisputeType _dispute) payable {
        
        bond = ContractUtility.Bond(
            _issuer,
            _owner,
            _bondName, // contract title
            _bondCode,
            ContractUtility.SecuritiesState.ISSUED,
            _quantity,
            _issueDate,
            _issueDate.add(_maturity.mul(365 days)),
            _couponRate,
            _couponPaymentInterval,
            _faceValue.mul(_quantity),
            _faceValue,
            _redemptionValue,
            _issueDate.add(_couponPaymentInterval.mul(30 days))
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.BOND,
            _dispute, _issuer, _owner, _walletIssuer, _walletOwner);
    }

    // buy the bond
    function buy() external payable contractReady bondHolderOnly {
        require(bond.state == ContractUtility.SecuritiesState.ISSUED, "Bond should be issuing!");
        require(msg.value == bond.bondPrice.mul(bond.quantity), "The amount is not correct!");

        bond.state = ContractUtility.SecuritiesState.ACTIVE;

        emit BuyBond(msg.value);
    }

    // sell the bond
    function transfer(address payable _transferee) public contractReady bondHolderOnly isActive {
        require(block.timestamp >= bond.maturity, "Bond has been redeemed");
        bond.owner = _transferee;

        emit TransferBond(_transferee);
    }

    // bond issuer collect fund (bond price) paid
    function collectFund() public contractReady issuerOnly isActive {
        require(!isFundCollected, "Fund has been collected!");

        bond.issuer.transfer(bond.bondPrice.mul(bond.quantity));
        isFundCollected = true;

        emit CollectFund(bond.bondPrice.mul(bond.quantity));
    }

    // bond issuer pays coupon to bond holder periodically
    function payCoupon() external payable contractReady issuerOnly isActive {
        require(block.timestamp >= bond.couponPaymentDate, "Coupon payment date has not reached!");
        require(msg.value == bond.couponRate.mul(bond.faceValue).mul(bond.quantity)
            .div(bond.couponPaymentInterval).div(100), "The amount is not correct!");
        
        cummulativeCouponValue = cummulativeCouponValue.add(msg.value);
        bond.couponPaymentDate = bond.couponPaymentDate.add(bond.couponPaymentInterval);

        emit PayCoupon(msg.value);
    }

    // bond issuer pays redemption value to bond holder at the last term of bond
    function payRedemption() external payable contractReady issuerOnly isActive {
        require(block.timestamp >= bond.maturity, "Bond has not matured!");
        require(msg.value == bond.redemptionValue.mul(bond.quantity), 
            "The amount is not correct!");
        require(!isRedemptionReady, "Redemption is ready!");
        
        isRedemptionReady = true;

        emit PayRedemption(msg.value);
    }

    // bond holder redeems coupon, assume coupon could be redeemed once released
    function redeemCoupon() public contractReady bondHolderOnly isActive {
        require(cummulativeCouponValue > 0, "No coupon to redeem!");
        require(address(this).balance >= cummulativeCouponValue, "Insufficient balance!");

        bond.owner.transfer(cummulativeCouponValue);
        cummulativeCouponValue = 0;

        emit RedeemCoupon(cummulativeCouponValue);
    }

    // complete contract
    function endBond() public contractReady isActive {
        require(msg.sender == bond.issuer || msg.sender == bond.owner, "You are not invloved in this bond!");
        require(block.timestamp >= bond.maturity, "Bond has not matured!");
        require(isRedemptionReady, "Redemption is not ready!");
        require(cummulativeCouponValue == 0, "Coupon has not been redeemed!");
        require(address(this).balance >= bond.redemptionValue.mul(bond.quantity), 
            "Insufficient balance!");

        bond.owner.transfer(bond.redemptionValue.mul(bond.quantity));
        bond.state = ContractUtility.SecuritiesState.REDEEMED;
        base.completeContract(contractId);
        emit EndBond(bond.redemptionValue.mul(bond.quantity));
        selfdestruct(payable(address(this)));
    }
}