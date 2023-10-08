// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

contract FutureContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Future public future;
    bool otherInit = false;

    event BuyerInit();
    event SellerInit();
    event SettleFuture();
    event RevertFuture();

    constructor(BaseContract _base, address _seller, address _buyer, DeTrustToken _wallet, address _derivativeAddress, 
        ContractUtility.ObjectType _assetType, uint256 _assetCode, uint256 _quantity, uint256 _deliveryDays, 
        uint256 _futurePrice, uint256 _deposit, string memory _description,
        ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {

        future = ContractUtility.Future(
            _wallet, 
            _seller, 
            _buyer, 
            ContractUtility.DerivativeState.PENDING,
            _assetType, 
            _assetType == ContractUtility.ObjectType.TOKEN ? IERC20(_derivativeAddress) : IERC20(address(0)),
            _assetType == ContractUtility.ObjectType.NFT ? IERC721(_derivativeAddress) : IERC721(address(0)),
            _assetCode,
            _quantity, 
            block.timestamp.add(_deliveryDays.mul(1 days)), 
            _futurePrice, 
            _futurePrice.mul(3).div(2), 
            _deposit, 
            false,
            _description);

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.FUTURE,
            _consensus, _dispute, _seller, _buyer);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    modifier deliveryDatePassed() {
        require(block.timestamp >= future.deliveryDate, "Delivery date has not reached!");
        future.state = ContractUtility.DerivativeState.EXPIRED;
        _;
    }

    function buyerInit() public {
        // buyer verify the future contract
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(future.state == ContractUtility.DerivativeState.PENDING, "Future contract has been verified!");
        require(msg.sender == future.buyer, "You are not the buyer!");
        future.deTrustToken.transfer(future.seller, future.premium);
        if (otherInit) {
            future.state = ContractUtility.DerivativeState.ACTIVE;
        } else {
            otherInit = true;
        }
        emit BuyerInit();
    }

    function sellerInit() public {
        // seller verify the future contract
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(future.state == ContractUtility.DerivativeState.PENDING, "Future contract has been verified!");
        require(msg.sender == future.seller, "You are not the seller!");

        if (future.assetType == ContractUtility.ObjectType.NFT) {
            future.asset_nft.transferFrom(future.seller, address(this), future.assetCode);
        } else {
            future.asset_token.transferFrom(future.seller, address(this), future.quantity);
        }
        if (otherInit) {
            future.state = ContractUtility.DerivativeState.ACTIVE;
        } else {
            otherInit = true;
        }
        emit SellerInit();
    }

    function checkMarginPrice() public returns (bool) {
        // check margin maintainance that a traders must maintain to enter / hold a future position
        require(future.state == ContractUtility.DerivativeState.ACTIVE, "Future contract has not been verified!");
        require(block.timestamp < future.deliveryDate, "Delivery date has reached!");

        if (future.deTrustToken.balanceOf(future.buyer) < future.margin) {
            if (future.isHold) {
                _revertFuture();
            } else {
                future.isHold = true;
            }
            return false;
        }
        return true;
    }

    function settle() public deliveryDatePassed {
        // deliver the underlying asset to the buyer
        // transfer token with futures
        require(future.state == ContractUtility.DerivativeState.ACTIVE, "Future contract has not been verified!");
        require(msg.sender == future.buyer, "You are not the buyer!");

        future.deTrustToken.transfer(future.seller, future.futurePrice.sub(future.premium));

        if (future.assetType == ContractUtility.ObjectType.NFT) {
            future.asset_nft.transferFrom(address(this), future.buyer, future.assetCode);
        } else {
            future.asset_token.transferFrom(address(this), future.buyer, future.quantity);
        }

        emit SettleFuture();
    }

    function _revertFuture() internal {
        // revert the future contract
        if (future.assetType == ContractUtility.ObjectType.NFT) {
            future.asset_nft.transferFrom(address(this), future.seller, future.assetCode);
        } else {
            future.asset_token.transferFrom(address(this), future.seller, future.quantity);
        }

        selfdestruct(payable(address(this)));

        emit RevertFuture();
    }

}