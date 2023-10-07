// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract OptionContract {
    enum OptionType { CALL, PUT } // holder to buy / holder to sell
    enum OptionStyle { AMERICAN, EUROPEAN } // anytime / only on maturity

    address optionSeller; // short position
    address optionBuyer; // long position
    OptionType optionType;
    OptionStyle optionStyle;
    string asset;
    string code;
    uint256 quantity;
    uint256 deliveryDate;
    uint256 strikePrice;
    uint256 optionPremium;
    uint256 premiumPaymentDate;
    uint256 margin;

    constructor(address _seller, address _buyer, OptionType _optionType, OptionStyle _optionStyle, 
        string memory _asset, string memory _code, uint256 _quantity, uint256 _deliveryDate, 
        uint256 _strikePrice, uint256 _optionPremium, uint256 _premiumPaymentDate, uint256 _margin) {
        optionSeller = _seller;
        optionBuyer = _buyer;
        optionType = _optionType;
        optionStyle = _optionStyle;
        asset = _asset;
        code = _code;
        quantity = _quantity;
        deliveryDate = _deliveryDate;
        strikePrice = _strikePrice;
        optionPremium = _optionPremium;
        premiumPaymentDate = _premiumPaymentDate;
        margin = _margin;
    }

    function checkMarginPrice() public pure returns (bool) {
        // check margin maintainance that a traders must maintain to enter / hold a future position
        return true;
    }

    function settle() public view {
        // deliver the underlying asset to the buyer
        // transfer token with futures
        if (optionType == OptionType.CALL) {
            // if the option is call, the buyer can exercise the option
        } else {
            // if the option is put, the seller can exercise the option
        }
    }

    function hold() public {
        // hold the underlying asset
    }

    function revertFuture() public {
        // revert the future contract
    }
}