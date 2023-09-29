// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserProfiles {
    address private userAddress;

    constructor() {

    }
    
    function getUserAddress() public view returns (address) {
        return userAddress;
    }
}