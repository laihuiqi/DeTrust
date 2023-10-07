// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractObjectToken {
    enum ObjectType { MutualFund, Service, Purchase, SmartVoucher }

    uint256 public id;
    address public owner;
    string public name;
    ObjectType objectType;
    string public symbol;
    uint256 public totalSupply;
    uint256 public decimals;
    string public description;

    uint256 objectRefCounter = 0;

    constructor(address _owner, string memory _name, ObjectType _objectType, 
        string memory _symbol, uint256 _totalSupply, uint256 _decimals, string memory _description) {
        id = ++objectRefCounter;
        owner = _owner;
        name = _name;
        objectType = _objectType;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;
        description = _description;
    }
}