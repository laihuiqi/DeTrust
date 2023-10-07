// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../../ContractObjectToken.sol";
import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";

contract FutureContract {
    using SafeMath for uint256;
    enum ObjectType { Token, Nft }

    DeTrustToken deTrustToken;
    address seller;
    address buyer;
    ObjectType assetType;
    IERC20 asset_token;
    IERC721 asset_nft;
    uint256 quantity;
    uint256 deliveryDate;
    uint256 futurePrice;
    uint256 margin;
    uint256 premium;
    bool isHold;
    string description;

    event BuyerVerify();
    event SellerVerify();
    event SettleFuture();
    event RevertFuture();

    constructor(address _seller, address _buyer, DeTrustToken _wallet, address _derivativeAddress, ObjectType _assetType,
        uint256 _quantity, uint256 _deliveryDays, uint256 _futurePrice, uint256 _deposit, string memory _description) {
        deTrustToken = _wallet;
        seller = _seller;
        buyer = _buyer;
        assetType = _assetType;
        if (assetType == ObjectType.Nft) {
            asset_nft = IERC721(_derivativeAddress);
        } else {
            asset_token = IERC20(_derivativeAddress);
        }
        quantity = _quantity;
        deliveryDate = block.timestamp + _deliveryDays.mul(1 days);
        futurePrice = _futurePrice;
        margin = _futurePrice.mul(3).div(2);
        premium = _deposit;
        description = _description;
    }

    modifier deliveryDatePassed() {
        require(block.timestamp >= deliveryDate, "Delivery date has not reached!");
        _;
    }

    function buyerVerify() public {
        // buyer verify the future contract
        require(msg.sender == buyer, "You are not the buyer!");
        deTrustToken.transfer(address(this), premium);
        emit BuyerVerify();
    }

    function sellerVerify() public {
        // seller verify the future contract
        require(msg.sender == seller, "You are not the seller!");
        if (assetType == ObjectType.Nft) {
            asset_nft.transferFrom(seller, address(this), quantity);
        } else {
            asset_token.transferFrom(seller, address(this), quantity);
        }
        emit SellerVerify();
    }

    function checkMarginPrice() public returns (bool) {
        // check margin maintainance that a traders must maintain to enter / hold a future position
        if (deTrustToken.balanceOf(buyer) < margin) {
            if (isHold) {
                _revertFuture();
            } else {
                isHold = true;
            }
            return false;
        }
        return true;
    }

    function settle() public deliveryDatePassed {
        // deliver the underlying asset to the buyer
        // transfer token with futures
        deTrustToken.transfer(seller, futurePrice.sub(premium));
        if (assetType == ObjectType.Nft) {
            asset_nft.transferFrom(seller, buyer, quantity);
        } else {
            asset_token.transferFrom(seller, buyer, quantity);
        }

        emit SettleFuture();
    }

    function _revertFuture() internal {
        // revert the future contract
        deTrustToken.transfer(seller, premium);
        selfdestruct(payable(address(this)));

        emit RevertFuture();
    }

}