// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { ContractUtility as Type } from "../ContractUtility.sol";
import "../../UserProfiles.sol";
import "../../DisputeMechanism.sol";
import "../BaseContract.sol";

contract ConditionalPayment {
    BaseContract repoAddress;
    Type.BasicProperties _basicProperties;
    uint256 _amount;
    uint256 _releaseAfter;
    uint256 _releaseAmount;
    bool _isConditionMet;
    bool _isReleased;

    constructor(address base, address promisor, address promisee, Type.ContractType contractType, 
        uint256 contractDuration, uint256 creationCost, Type.DisputeType disputeType, 
        uint256 amount, uint256 releaseTime, uint256 releaseAmount) {
        
        repoAddress = BaseContract(base);
        _basicProperties = Type.BasicProperties({
            _id: repoAddress.getCounter(),
            _contractAddress: address(this),
            _promisor: UserProfiles(promisor),
            _promisee: UserProfiles(promisee),
            _consensus: Type.Consensus.NEW,
            _contractType: contractType,
            _createdAt: block.timestamp,
            _contractDuration: contractDuration,
            _currentCost: creationCost,
            _disputeType: disputeType,
            _disputeMechanism: DisputeMechanism(address(0))
        });

        _amount = amount;
        _releaseAfter = block.timestamp + releaseTime;
        _releaseAmount = releaseAmount;
        _isConditionMet = false;
        _isReleased = false;

        repoAddress.addToRepo(_basicProperties._id, _basicProperties);
    }

    modifier canReleasePayment(uint256 tokens) {
        require(_isConditionMet, "Condition not met");
        require(!_isReleased, "Payment already released");
        require(block.timestamp >= _releaseAfter, "Payment not yet released");
        require(tokens == _releaseAmount, "Incorrect amount");
        _;
    }

    function getPaymentAmount() public view returns (uint256) {
        return _amount;
    }

    function getReleaseTime() public view returns (uint256) {
        return _releaseAfter;
    }

    function getReleaseAmount() public view returns (uint256) {
        return _releaseAmount;
    }

    function isConditionMet() public view returns (bool) {
        return _isConditionMet;
    }

    function isReleased() public view returns (bool) {
        return _isReleased;
    }

    function setConditionMet(bool conditionMet) public {
        _isConditionMet = conditionMet;
    }

    function makePayment(uint256 tokens) public canReleasePayment(tokens) {
        // TODO: transfer tokens to promisee
        _isReleased = true;
    }
}