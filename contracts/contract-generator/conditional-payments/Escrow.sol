// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { ContractUtility as Type } from "../ContractUtility.sol";
import "../../UserProfiles.sol";
import "../../DisputeMechanism.sol";
import "../BaseContract.sol";
import "./ConditionalPayment.sol";

contract Escrow is ConditionalPayment {
    address _arbitratorAddress;
    UserProfiles _arbitrator;
    bool _isApproved;

    constructor(address base, address promisor, address promisee,  address arbitrator, uint256 contractDuration, 
        uint256 creationCost, Type.DisputeType dispute,  uint256 amount, uint256 releaseTime, uint256 releaseAmount) 
        ConditionalPayment(base, promisor, promisee, Type.ContractType.ESCROW, contractDuration,
            creationCost, dispute, amount, releaseTime, releaseAmount) {
        
        _arbitratorAddress = arbitrator;
        _arbitrator = UserProfiles(arbitrator);
        _isApproved = false;
    }

    modifier onlyArbitrator() {
        require(msg.sender == address(_arbitrator), "Only arbitrator can call this function");
        _;
    }

    modifier onlyPromisor() {
        require(msg.sender == address(_basicProperties._promisor), "Only promisor can call this function");
        _;
    }
       
    function promisorDeposit() public {
        // TODO: Promisor deposit amount to be transferred to this contract
    }

    function approveRelease() public onlyPromisor {
        _isApproved = true;

        if (_arbitratorAddress == address(this)) {
            releaseFund();
        }
    }

    function releaseFund() public onlyArbitrator {
        // TODO: Release fund to promisee
    }

    function checkApproval() public view returns (bool) {
        return _isApproved;
    }
}