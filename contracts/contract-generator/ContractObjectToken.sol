// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ContractObjectToken is ERC1155 {
    enum ObjectType { MutualFund, Service, Purchase, SmartVoucher }

    struct ObjectToken {
        uint256 id;
        address owner;
        string name;
        ObjectType objectType;
        string symbol;
        uint256 totalSupply;
        uint256 decimals;
        string description;
    }

    uint256 objectRefCounter = 0;

    mapping(uint256 => ObjectToken) public assets;

    constructor(address _owner, string memory _name, ObjectType _objectType, 
        string memory _symbol, uint256 _totalSupply, uint256 _decimals, string memory _description)
        ERC1155(_name) {
        objectRefCounter++;

        ObjectToken memory newAsset = ObjectToken({
            id: objectRefCounter,
            owner: _owner,
            name: _name,
            objectType: _objectType,
            symbol: _symbol,
            totalSupply: _totalSupply,
            decimals: _decimals,
            description: _description
        });

        assets[objectRefCounter] = newAsset;
    }

    function getAsset(uint256 _assetId) public view returns (ObjectToken memory) {
        // get the asset from the asset id
        return assets[_assetId];
    }

    function transfer(address _to, uint256 _assetId) public {
        // transfer the asset to another address
        // require(msg.sender == assets[_assetId].owner, "You are not the owner of this asset!");
        //transfer(msg.sender, _to, _assetId);
    }

}