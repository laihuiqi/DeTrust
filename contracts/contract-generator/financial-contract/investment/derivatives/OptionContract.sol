// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

contract OptionContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Option public option;
    bool otherInit = false;

    event BuyerInit();
    event SellerInit();

    constructor(BaseContract _base, address _seller, address _buyer, DeTrustToken _wallet, ContractUtility.OptionType _optionType,  
        address _derivativeAddress, ContractUtility.ObjectType _assetType, uint256 _assetCode, 
        uint256 _quantity, uint256 _deliveryDate, uint256 _strikePrice, uint256 _optionPremium,
        ContractUtility.Consensus _consensus, ContractUtility.DisputeType _dispute) {
        
        option = ContractUtility.Option(
            _wallet,
            _seller,
            _buyer,
            ContractUtility.DerivativeState.PENDING,
            _optionType,
            _assetType,
            _assetCode,
            _assetType == ContractUtility.ObjectType.TOKEN ? IERC20(_derivativeAddress) : IERC20(address(0)),
            _assetType == ContractUtility.ObjectType.NFT ? IERC721(_derivativeAddress) : IERC721(address(0)),
            _quantity,
            block.timestamp.add(_deliveryDate.mul(1 days)),
            _strikePrice,
            _optionPremium,
            _strikePrice.mul(3).div(2),
            false);
        
        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.OPTION,
            _consensus, _dispute, _seller, _buyer);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    modifier deliveryDatePassed() {
        require(block.timestamp >= option.deliveryDate, "Delivery date has not reached!");
        option.state = ContractUtility.DerivativeState.EXPIRED;
        _;
    }

    function buyerInit() public {
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(option.state == ContractUtility.DerivativeState.PENDING, "Option contract has been verified!");        require(msg.sender == option.optionBuyer, "You are not the buyer!");

        option.deTrustToken.transfer(option.optionSeller, option.optionPremium);
        agree();

        if (otherInit) {
            option.state = ContractUtility.DerivativeState.ACTIVE;
        } else {
            otherInit = true;
        }
        emit BuyerInit();
    }

    function sellerInit() public {
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(option.state == ContractUtility.DerivativeState.PENDING, "Option contract has been verified!");        require(msg.sender == option.optionSeller, "You are not the seller!");
        require(msg.sender == option.optionSeller, "You are not the seller!");

        agree();
        if (otherInit) {
            option.state = ContractUtility.DerivativeState.ACTIVE;
        } else {
            otherInit = true;
        }
        emit SellerInit();
    }

    function agree() internal {
        if ((option.optionType == ContractUtility.OptionType.CALL && msg.sender == option.optionBuyer) ||
            (option.optionType == ContractUtility.OptionType.PUT && msg.sender == option.optionSeller)) {
            option.deTrustToken.transfer(address(this), option.strikePrice.mul(option.quantity));
        } else {
            if (option.assetType == ContractUtility.ObjectType.NFT) {
                option.asset_nft.transferFrom(msg.sender, address(this), option.assetCode); 
            } else {
                option.asset_token.transferFrom(msg.sender, address(this), option.quantity);
            }
        }
    }

    function checkMarginPrice() public returns (bool) {
        // check margin maintainance that a traders must maintain to enter / hold a future position
        require(option.state == ContractUtility.DerivativeState.ACTIVE, "Option contract has not been verified!");
        require(block.timestamp < option.deliveryDate, "Delivery date has reached!");
        
        address toCheck = option.optionType == ContractUtility.OptionType.CALL 
                                                ? option.optionBuyer 
                                                : option.optionSeller;
        if (option.deTrustToken.balanceOf(toCheck) < option.margin) {
            if (option.isHold) {
                _revertOption();
            } else {
                option.isHold = true;
            }
            return false;
        }
        return true;
    }

    function exerciseOption() public deliveryDatePassed {
        require(msg.sender == option.optionBuyer, "You are not the option buyer!");
        // deliver the underlying asset to the buyer
        // transfer token with futures
        if (option.optionType == ContractUtility.OptionType.CALL) {
            // if the option is call, the buyer can exercise the option
            option.deTrustToken.transfer(option.optionSeller, option.strikePrice.mul(option.quantity));
            _returnAsset(option.optionBuyer);

        } else {
            // if the option is put, the seller can exercise the option
            option.deTrustToken.transfer(option.optionBuyer, option.strikePrice.mul(option.quantity));
            
            _returnAsset(option.optionSeller);
        }
    }

    function cancelExercise() public {
        require(option.state == ContractUtility.DerivativeState.ACTIVE, "Option contract has not been verified!");
        require(msg.sender == option.optionBuyer, "You are not the option buyer!");
        require(block.timestamp < option.deliveryDate, "Delivery date has reached!");

        if (option.optionType == ContractUtility.OptionType.PUT) {
            option.deTrustToken.transfer(option.optionSeller, option.strikePrice.mul(option.quantity));
            _returnAsset(option.optionBuyer);
        } else {
            option.deTrustToken.transfer(option.optionBuyer, option.strikePrice.mul(option.quantity));
            _returnAsset(option.optionSeller);
        }
    }

    function _revertOption() internal {
        // revert the option contract
        if (option.optionType == ContractUtility.OptionType.CALL) {
            option.deTrustToken.transfer(option.optionBuyer, option.optionPremium);
            _returnAsset(option.optionSeller);
        } else {
            option.deTrustToken.transfer(option.optionSeller, option.optionPremium);
            _returnAsset(option.optionBuyer);
        }
        
        selfdestruct(payable(address(this)));
    }

    function _returnAsset(address _returnAddress) internal {
        if (option.assetType == ContractUtility.ObjectType.NFT) {
            option.asset_nft.transferFrom(address(this), _returnAddress, option.assetCode);
        } else {
            option.asset_token.transferFrom(address(this), _returnAddress, option.quantity);
        } 
    }
}