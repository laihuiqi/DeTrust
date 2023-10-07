// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FutureContract {
    address seller;
    address buyer;
    string asset;
    string code;
    uint256 quantity;
    uint256 deliveryDate;
    uint256 futurePrice;
    uint256 margin;

    constructor(address _seller, address _buyer, string memory _asset, string memory _code, 
        uint256 _quantity, uint256 _deliveryDate, uint256 _futurePrice, uint256 _margin) {
        seller = _seller;
        buyer = _buyer;
        asset = _asset;
        code = _code;
        quantity = _quantity;
        deliveryDate = _deliveryDate;
        futurePrice = _futurePrice;
        margin = _margin;
    }

    function checkMarginPrice() public pure returns (bool) {
        // check margin maintainance that a traders must maintain to enter / hold a future position
        return true;
    }

    function settle() public {
        // deliver the underlying asset to the buyer
        // transfer token with futures
    }

    function hold() public {
        // hold the underlying asset
    }

    function revertFuture() public {
        // revert the future contract
    }

}