// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import { ContractUtility as Type } from "./ContractUtility.sol";
import "../UserProfiles.sol";
import "../DisputeMechanism.sol";

contract BaseContract {
    mapping(uint256 => Type.BasicProperties) private contractRepositories;

    uint256 counter = 0;

    constructor(address promisor, address promisee, Type.ContractType contractType, 
        uint256 contractDuration, uint256 creationCost, Type.DisputeType disputeType) {

        Type.BasicProperties memory basicProperties = Type.BasicProperties({
            _id: ++counter,
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

        contractRepositories[counter] = basicProperties;
    }

    modifier ownerOnly(uint id) {
        require(msg.sender == getPromisor(id).getUserAddress());
        _;
    }

    function getContract(uint id) public view returns (Type.BasicProperties memory) {
        return contractRepositories[id];
    }

    function getContractAddress(uint id) public view returns (address) {
        return contractRepositories[id]._contractAddress;
    }

    function getPromisor(uint id) public view returns (UserProfiles) {
        return contractRepositories[id]._promisor;
    }

    function getPromisee(uint id) public view returns (UserProfiles) {
        return contractRepositories[id]._promisee;
    }

    function getConsensus(uint id) public view returns (Type.Consensus) {
        return contractRepositories[id]._consensus;
    }

    function getContractType(uint id) public view returns (Type.ContractType) {
        return contractRepositories[id]._contractType;
    }

    function getCreationTime(uint id) public view returns (uint256) {
        return contractRepositories[id]._createdAt;
    }

    function getContractDuration(uint id) public view returns (uint256) {
        return contractRepositories[id]._contractDuration;
    }

    function getEndTime(uint id) public view returns (uint256) {
        return contractRepositories[id]._createdAt 
            + contractRepositories[id]._contractDuration;
    }

    function getCurrentCost(uint id) public view returns (uint256) {
        return contractRepositories[id]._currentCost;
    }

    function getDisputeType(uint id) public view returns (Type.DisputeType) {
        return contractRepositories[id]._disputeType;
    }

    function getDisputeMechanism(uint id) public view returns (DisputeMechanism) {
        return contractRepositories[id]._disputeMechanism;
    }

    function setConsensus(uint id, Type.Consensus consensus) internal {
        contractRepositories[id]._consensus = consensus;
    }

    function setContractDuration(uint id, uint256 duration) public ownerOnly(id) {
        contractRepositories[id]._contractDuration = duration;
    }

    function setCurrentCost(uint id, uint256 cost) internal  {
        contractRepositories[id]._currentCost = cost;
    }

    function setDisputeType(uint id, Type.DisputeType _type) public ownerOnly(id) {
        contractRepositories[id]._disputeType = _type;
    }

    function setDisputeMechanism(uint id, address dispute) public ownerOnly(id) {
        contractRepositories[id]._disputeMechanism = DisputeMechanism(dispute);
    }

    function extendContractBy(uint id, uint256 _days) public ownerOnly(id) {
        setContractDuration(id, getContractDuration(id) + _days * 1 days);
    }

    function shortenContractBy(uint id, uint256 _days) public ownerOnly(id) {
        setContractDuration(id, getContractDuration(id) - _days * 1 days);
    }

    function increaseContractCost(uint id, uint256 _amount) internal {
        setCurrentCost(id, getCurrentCost(id) + _amount);
    }

    function decreaseContractCost(uint id, uint256 _amount) internal {
        setCurrentCost(id, getCurrentCost(id) - _amount);
    }
}
