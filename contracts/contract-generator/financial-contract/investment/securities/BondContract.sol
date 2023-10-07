// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";

contract BondContract {
    using SafeMath for uint256;

    enum BondState { Issued, Active, Redeemed }
    DeTrustToken deTrustToken;

    address issuer;
    address owner;
    string bondName;
    string bondCode;
    BondState state;
    uint256 quantity;
    uint256 issueDate;
    uint256 maturity;
    uint256 couponRate;
    uint256 couponPaymentInterval;
    uint256 bondPrice;
    uint256 faceValue;
    uint256 redemptionValue;
    uint256 couponPaymentDate;

    mapping(address => uint256) public holders;

    constructor(address _issuer, address _owner, DeTrustToken _wallet, string memory _bondName, 
        string memory _bondCode, uint256 _quantity, uint256 _issueDate, uint256 _maturity, 
        uint256 _couponRate, uint256 _couponPaymentInterval, uint256 _faceValue, 
        uint256 _redemptionValue) {
        deTrustToken = _wallet;
        issuer = _issuer;
        owner = _owner;
        bondName = _bondName;
        bondCode = _bondCode;
        state = BondState.Issued;
        quantity = _quantity;
        issueDate = _issueDate;
        maturity = issueDate.add(_maturity);
        couponRate = _couponRate;
        couponPaymentInterval = _couponPaymentInterval;
        faceValue = _faceValue;
        bondPrice = faceValue.mul(quantity);
        redemptionValue = _redemptionValue;
        couponPaymentDate = issueDate.add(_couponPaymentInterval);
    }

    function buy() public {
        // buy the bond
        require(state == BondState.Issued, "Bond should be issuing!");
        require(msg.sender == owner, "You are not the bond holder!");

        deTrustToken.transfer(issuer, bondPrice);
        state = BondState.Active;
    }

    function transfer(address _transferee) public {
        // sell the bond
        require(msg.sender == owner);
        owner = _transferee;
    }

    function payCoupon() public {
        require(msg.sender == issuer, "Only issuer can pay coupon!");
        require(state == BondState.Active, "Bond should be active!");
        require(block.timestamp >= couponPaymentDate, "Coupon payment date has not reached!");
        
        deTrustToken.transfer(owner, couponRate.mul(faceValue).div(couponPaymentInterval).div(100));
        couponPaymentDate = couponPaymentDate.add(couponPaymentInterval);
    }

    function payRedemption() public {
        require(msg.sender == issuer, "Only issuer can pay redemption!");
        require(block.timestamp >= maturity, "Bond has not matured!");
        
        deTrustToken.transfer(owner, redemptionValue);
        state = BondState.Redeemed;
    }

    function endBond() public {
        require(state == BondState.Redeemed, "Bond should be redeemed!");

        selfdestruct(payable(address(this)));
    }
}