// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

/**
 * @title OptionContract
 * @dev The base contract for option contract
 */
contract OptionContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Option public option;
    bool premiumPaid = false;
    bool isExercised = false;

    event ContractInit(uint256 _value);
    event PurchaserVerified();
    event OptionExercised();
    event OptionCancelled();
    event OptionReverted();
    event VerifyTransfer();

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    modifier purchaserOnly() {
        require((option.optionType == ContractUtility.OptionType.CALL && msg.sender == option.optionBuyer) ||
            (option.optionType == ContractUtility.OptionType.PUT && msg.sender == option.optionSeller), 
            "You are not qualified to execute this function");
        _;
    }

    modifier optionCanExercise() {
        require(msg.sender == option.optionBuyer, "You are not the option buyer!");
        require(option.state == ContractUtility.DerivativeState.ACTIVE, "Option contract is not active!");
        require(block.timestamp >= option.deliveryDate, "Delivery date has not reached!");
        _;
    }

    constructor(BaseContract _base, address payable _seller, address payable _buyer, ContractUtility.OptionType _optionType,  
        uint256 _assetCode, string memory _assetType, uint256 _quantity, uint256 _deliveryDate, uint256 _strikePrice, uint256 _optionPremium,
        ContractUtility.DisputeType _dispute) payable {
        
        option = ContractUtility.Option(
            _seller,
            _buyer,
            ContractUtility.DerivativeState.PENDING,
            _optionType,
            _assetType,
            _assetCode,
            _quantity,
            block.timestamp.add(_deliveryDate.mul(1 days)),
            _strikePrice,
            _optionPremium);
        
        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.OPTION,
            _dispute, _seller, _buyer);
    }

    // buyer of the option init the contract by paying the premium to the contract
    function buyerInit() external payable contractReady purchaserOnly {
        require(option.state == ContractUtility.DerivativeState.PENDING, "Option contract has been verified!");        
        require(msg.sender == option.optionBuyer, "You are not the buyer!");
        require(msg.value == option.optionPremium, "Option premium is not correct!");

        option.optionSeller.transfer(option.optionPremium);
        premiumPaid = true;
        
        emit ContractInit(msg.value);
    }

    // purchaser of goods agrees and sends strike price to the contract
    function purchaserVerify() external payable contractReady purchaserOnly {
        require(msg.value == option.strikePrice.mul(option.quantity), "Amount is not correct!");
        require(premiumPaid, "Premium has not been paid!");

        option.state = ContractUtility.DerivativeState.ACTIVE;

        emit PurchaserVerified();
    }

    // purchaser verifies product delivery
    function verifyTransfer() public contractReady {
        require(isExercised, "Option has not been exercised!");

        option.state = ContractUtility.DerivativeState.EXPIRED;
        base.completeContract(contractId);

        emit VerifyTransfer();

        selfdestruct(payable(address(this)));
    }

    // buyer of option exercise the option
    function exerciseOption() public contractReady optionCanExercise {
        require(address(this).balance >= option.strikePrice.mul(option.quantity), "Contract does not have enough money to exercise!");
        
        if (option.optionType == ContractUtility.OptionType.CALL) {
            // if the option is call, the buyer can exercise the option
            option.optionSeller.transfer(option.strikePrice.mul(option.quantity));

        } else {
            // if the option is put, the seller can exercise the option
            option.optionBuyer.transfer(option.strikePrice.mul(option.quantity));
            
        }

        isExercised = true;

        emit OptionExercised();
    }

    // buyer of option cancel the option
    function cancelExercise() public contractReady optionCanExercise {
        require(address(this).balance >= option.strikePrice.mul(option.quantity).add(option.strikePrice.mul(option.quantity)), 
            "Contract does not have enough money to exercise!");

        if (option.optionType == ContractUtility.OptionType.PUT) {
            option.optionBuyer.transfer(option.strikePrice.mul(option.quantity));
            option.optionSeller.transfer(option.strikePrice.mul(option.quantity));

        } else {
            option.optionBuyer.transfer(option.strikePrice.mul(option.quantity));
            option.optionBuyer.transfer(option.strikePrice.mul(option.quantity));
        }
        base.completeContract(contractId);

        emit OptionCancelled();

        selfdestruct(payable(address(this)));
    }

    // revert the option contract before paying the strike price
    function revertOption() external payable contractReady {
        require(msg.sender == option.optionBuyer || msg.sender == option.optionSeller, 
            "You are not involved in this option!");
        require(option.state == ContractUtility.DerivativeState.PENDING, 
            "Option contract has been activated!");
        require(address(this).balance >= option.strikePrice.mul(option.quantity), 
            "Contract does not have enough money to exercise!");

        if (option.optionType == ContractUtility.OptionType.CALL) {
            option.optionBuyer.transfer(option.optionPremium);

        } else {
            option.optionSeller.transfer(option.optionPremium);

        }

        base.voidContract(contractId);
        emit OptionReverted();
        
        selfdestruct(payable(address(this)));
    }

}