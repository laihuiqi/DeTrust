// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeTrustToken is ERC20 {
    address private owner;
    uint256 private _maxSupply;
    uint256 private _exchange = 0.01 ether;

    mapping(address => uint8) approvedAddress;

    constructor(uint256 maxSupply_) ERC20("DeTrustToken", "DTR") {
        _maxSupply = maxSupply_;
        owner = msg.sender;
        approvedAddress[owner] = 1;
    }

    // Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier exceedMax(uint256 amount) {
        require(_maxSupply >= totalSupply() + amount);
        _;
    }

    modifier enoughPayment(uint256 amount) {
        require(msg.value >= amount * _exchange);
        _;
    }

    modifier enoughSupply(uint256 amount) {
        require(balanceOf(thisAddress()) >= amount);
        _;
    }

    modifier onlyApproved() {
        require(approvedAddress[msg.sender] == 1, "Not approved!");
        _;
    }

    // Functions
    function setApproval(address toApprove) public onlyOwner {
        approvedAddress[toApprove] = 1;
    }

    function mint(uint256 amount) public exceedMax(amount) {
        _mint(thisAddress(), amount);
    }

    function mintFor(address addr, uint256 amount) public exceedMax(amount) onlyApproved {
        _mint(addr, amount);
    }

    function burn(uint256 amount) public enoughSupply(amount) {
        _burn(thisAddress(), amount);
    }

    function burnFor(address addr, uint256 amount) public exceedMax(amount) onlyApproved {
        _burn(addr, amount);
    }

    function topUp(
        uint256 numTokens
    ) public payable enoughPayment(numTokens) enoughSupply(numTokens) {
        transferFrom(thisAddress(), msg.sender, numTokens);
    }

    // Getters & Setters
    function thisAddress() internal view returns (address) {
        return address(this);
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function availableTokens() public view returns (uint256) {
        return balanceOf(thisAddress());
    }

    function setExchange(uint256 exchange_) public onlyOwner {
        _exchange = exchange_;
    }
}
