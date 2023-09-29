// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { ContractUtility as Type } from "../ContractUtility.sol";
import "../../UserProfiles.sol";
import "../../DisputeMechanism.sol";
import "../BaseContract.sol";
import "./ConditionalPayment.sol";

contract SimplePayment is ConditionalPayment {
    constructor(address base, address promisor, address promisee,  uint256 contractDuration, 
        uint256 creationCost, uint256 amount, uint256 releaseTime, uint256 releaseAmount) 
        ConditionalPayment(base, promisor, promisee, Type.ContractType.SIMPLE_PAYMENT, contractDuration,
            creationCost, Type.DisputeType.NONE, amount, releaseTime, releaseAmount) {
        super.setConditionMet(true);
    }
}