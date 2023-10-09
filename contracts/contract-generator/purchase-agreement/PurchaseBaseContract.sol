// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../DeTrustToken.sol";
import "../ContractUtility.sol";
import "../BaseContract.sol";

contract PurchaseBaseContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Purchase public purchase;

    constructor(BaseContract _base, address _seller, address _buyer, DeTrustToken _wallet, string memory _description, 
        uint256 _price, uint256 _paymentDate, uint256 _deliveryDate, ContractUtility.Consensus _consensus, 
        ContractUtility.DisputeType _dispute) {
        
        purchase = ContractUtility.Purchase(
            _wallet,
            _seller,
            _buyer,
            _description,
            _price,
            _paymentDate,
            _deliveryDate,
            false,
            false
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.PURCHASE,
            _consensus, _dispute, _seller, _buyer);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    function pay() public {
        // pay the seller
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(!purchase.isPaid, "Payment has been made!");
        require(purchase.paymentDate <= block.timestamp, "Payment date has not reached!");
        require(msg.sender == purchase.buyer, "You are not the buyer!");

        purchase.deTrustToken.transfer(address(this), purchase.price);
        purchase.isPaid = true;
    }

    function withdraw() public {
        // withdraw the payment
        require(purchase.isPaid, "Payment has not been made!");
        require(msg.sender == purchase.seller, "You are not the seller!");
        require(purchase.paymentDate <= block.timestamp, "Payment date has not reached!");
        require(purchase.isReceived, "Product has not been received!");
        
        purchase.deTrustToken.transfer(purchase.seller, purchase.price);
    }

    function receiveProduct() public {
        require(msg.sender == purchase.buyer, "You are not the buyer!");

        purchase.isReceived = true;
    }

    function terminate() public {
        // terminate the contract
        require(msg.sender == purchase.buyer || msg.sender == purchase.seller, 
            "You are not involved in this contract!");
        require((block.timestamp >= purchase.deliveryDate && !purchase.isReceived) || 
            (block.timestamp >= purchase.paymentDate && !purchase.isPaid), "Delivery date has not reached!");
        
        if (purchase.isPaid) {
            purchase.deTrustToken.transfer(purchase.buyer, purchase.price);
        }
        selfdestruct(payable(address(this)));
    }
}