// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

contract BondContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Bond public bond;

    constructor(BaseContract _base, address _issuer, address _owner, DeTrustToken _wallet, string memory _bondName, 
        string memory _bondCode, uint256 _quantity, uint256 _issueDate, uint256 _maturity, 
        uint256 _couponRate, uint256 _couponPaymentInterval, uint256 _faceValue, 
        uint256 _redemptionValue, ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {
        
        bond = ContractUtility.Bond(
            _wallet,
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
            _issueDate.add(_couponPaymentInterval.mul(30 days)),
            0,
            false
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.BOND,
            _consensus, _dispute, _issuer, _owner);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    function buy() public {
        // buy the bond
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(bond.state == ContractUtility.SecuritiesState.ISSUED, "Bond should be issuing!");
        require(msg.sender == bond.owner, "You are not the bond holder!");

        bond.deTrustToken.transfer(bond.issuer, bond.bondPrice);
        bond.state = ContractUtility.SecuritiesState.ACTIVE;
    }

    function transfer(address _transferee) public {
        // sell the bond
        require(msg.sender == bond.owner);
        require(bond.state == ContractUtility.SecuritiesState.ACTIVE, "Bond should be active!");
        require(block.timestamp >= bond.maturity, "Bond has been redeemed");
        bond.owner = _transferee;
    }

    function payCoupon() public {
        require(msg.sender == bond.issuer, "Only issuer can pay coupon!");
        require(bond.state == ContractUtility.SecuritiesState.ACTIVE, "Bond should be active!");
        require(block.timestamp >= bond.couponPaymentDate, "Coupon payment date has not reached!");
        
        bond.cummulativeCoupon = bond.cummulativeCoupon.add(1);
        bond.deTrustToken.approve(bond.owner, bond.couponRate.mul(bond.faceValue).div(bond.couponPaymentInterval).div(100));
        bond.couponPaymentDate = bond.couponPaymentDate.add(bond.couponPaymentInterval);
    }

    function payRedemption() public {
        require(msg.sender == bond.issuer, "Only issuer can pay redemption!");
        require(block.timestamp >= bond.maturity, "Bond has not matured!");
        
        bond.isRedemptionReady = true;
        bond.deTrustToken.approve(bond.owner, bond.redemptionValue);
    }

    function redeemCoupon() public {
        require(msg.sender == bond.owner, "Only bond holder can redeem coupon!");
        require(bond.state == ContractUtility.SecuritiesState.ACTIVE, "Bond should be active!");
        require(bond.cummulativeCoupon > 0, "No coupon to redeem!");

        bond.cummulativeCoupon = 0;
        bond.deTrustToken.transferFrom(bond.issuer, bond.owner,
            bond.couponRate.mul(bond.faceValue).mul(bond.cummulativeCoupon)
                .div(bond.couponPaymentInterval).div(100));
    }

    function redeemBond() public {
        require(msg.sender == bond.owner, "Only bond holder can redeem bond!");
        require(bond.state == ContractUtility.SecuritiesState.ACTIVE, "Bond should be active!");
        require(block.timestamp >= bond.maturity, "Bond has not matured!");
        require(bond.isRedemptionReady, "Redemption is not ready!");

        bond.isRedemptionReady = false;
        bond.deTrustToken.transferFrom(bond.issuer, bond.owner, bond.redemptionValue);
        bond.state = ContractUtility.SecuritiesState.REDEEMED;
    }

    function endBond() public {
        require(bond.state == ContractUtility.SecuritiesState.REDEEMED, "Bond should be redeemed!");

        selfdestruct(payable(address(this)));
    }
}