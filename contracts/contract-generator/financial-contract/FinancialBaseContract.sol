// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseContract.sol";

/**
 * @title FinancialBaseContract
 * @dev FinancialBaseContract is a base contract for financial contracts. 
 * It contains the basic functions and variables needed for financial contracts including 
 * resources loans and investment services.
 */
contract FinancialBaseContract is BaseContract {
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

    function getAmount() public view returns (uint256) {
        return _amount;
    }
}