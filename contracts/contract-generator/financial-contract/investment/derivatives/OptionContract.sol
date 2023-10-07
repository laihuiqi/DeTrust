// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../ContractObjectToken.sol";
import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";

contract OptionContract {
    using SafeMath for uint256;

    DeTrustToken deTrustToken;
    enum ObjectType { Token, Nft }
    enum OptionType { CALL, PUT } // holder to buy / holder to sell

    address optionSeller; // short position
    address optionBuyer; // long position
    OptionType optionType;
    ObjectType assetType;
    IERC20 asset_token;
    IERC721 asset_nft;
    uint256 quantity;
    uint256 deliveryDate;
    uint256 strikePrice;
    uint256 optionPremium;
    uint256 margin;
    bool isHold;

    event BuyerVerify();
    event SellerVerify();

    constructor(address _seller, address _buyer, DeTrustToken _wallet, OptionType _optionType,  
        address _derivativeAddress, ObjectType _assetType, uint256 _quantity, uint256 _deliveryDate, 
        uint256 _strikePrice, uint256 _optionPremium) {
        optionSeller = _seller;
        optionBuyer = _buyer;
        deTrustToken = _wallet;
        optionType = _optionType;
        assetType = _assetType;
        if (assetType == ObjectType.Nft) {
            asset_nft = IERC721(_derivativeAddress);
        } else {
            asset_token = IERC20(_derivativeAddress);
        }
        quantity = _quantity;
        deliveryDate = block.timestamp + _deliveryDate.mul(1 days);
        strikePrice = _strikePrice;
        optionPremium = _optionPremium;
        margin = _strikePrice.mul(3).div(2);
    }

    modifier deliveryDatePassed() {
        require(block.timestamp >= deliveryDate, "Delivery date has not reached!");
        _;
    }

    function buyerVerify() public {
        require(msg.sender == optionBuyer, "You are not the buyer!");
        deTrustToken.transfer(optionSeller, optionPremium);
        agree();
        emit BuyerVerify();
    }

    function sellerVerify() public {
        require(msg.sender == optionSeller, "You are not the seller!");
        agree();
        emit SellerVerify();
    }

    function agree() internal {
        if ((optionType == OptionType.CALL && msg.sender == optionBuyer) ||
            (optionType == OptionType.PUT && msg.sender == optionSeller)) {
            deTrustToken.transfer(address(this), strikePrice.mul(quantity));
        } else {
            if (assetType == ObjectType.Nft) {
                asset_nft.approve(address(this), quantity); // token_id?
            } else {
                asset_token.approve(address(this), quantity);
            }
        }
    }

    function checkMarginPrice() public returns (bool) {
        // check margin maintainance that a traders must maintain to enter / hold a future position
        address toCheck = optionType == OptionType.CALL ? optionBuyer : optionSeller;
        if (deTrustToken.balanceOf(toCheck) < margin) {
            if (isHold) {
                _revertOption();
            } else {
                isHold = true;
            }
            return false;
        }
        return true;
    }

    function exerciseOption() public {
        require(msg.sender == optionBuyer, "You are not the option buyer!");
        // deliver the underlying asset to the buyer
        // transfer token with futures
        if (optionType == OptionType.CALL) {
            // if the option is call, the buyer can exercise the option
            deTrustToken.transfer(optionSeller, strikePrice.mul(quantity));
            if (assetType == ObjectType.Nft) {
                asset_nft.transferFrom(optionSeller, optionBuyer, quantity);
            } else {
                asset_token.transferFrom(optionSeller, optionBuyer, quantity);
            }

        } else {
            // if the option is put, the seller can exercise the option
            deTrustToken.transfer(optionBuyer, strikePrice.mul(quantity));
            if (assetType == ObjectType.Nft) {
                asset_nft.transferFrom(optionBuyer, optionSeller, quantity);
            } else {
                asset_token.transferFrom(optionBuyer, optionSeller, quantity);
            }
        }
    }

    function cancelExercise() public {
        require(msg.sender == optionBuyer, "You are not the option buyer!");
        if (optionType == OptionType.PUT) {
            deTrustToken.transfer(optionSeller, strikePrice.mul(quantity));
        } else {
            deTrustToken.transfer(optionBuyer, strikePrice.mul(quantity));
        }
    }

    function _revertOption() internal {
        // revert the option contract
        if (optionType == OptionType.CALL) {
            deTrustToken.transfer(optionBuyer, optionPremium);
        } else {
            deTrustToken.transfer(optionSeller, optionPremium);
        }
        selfdestruct(payable(address(this)));
    }
}