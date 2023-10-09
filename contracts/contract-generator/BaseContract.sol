// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ContractUtility.sol";
import "../DisputeMechanism.sol";

contract BaseContract {

    using SafeMath for uint256;

    uint256 counter = 0;

    struct BasicProperties {
        uint256 _id;
        ContractUtility.ContractType _contractType;
        ContractUtility.Consensus _consensus;
        ContractUtility.DisputeType _disputeType;
        DisputeMechanism _disputeMechanism;
        address payer;
        ContractUtility.Signature _ad1;
        address payee;
        ContractUtility.Signature _ad2;
        uint256 isSigned;
        uint256 isVerified;
    }

    mapping(uint256 => BasicProperties) public generalRepo;
    mapping(address => uint256) public idToAddressRepo;

    function sign(uint256 contractId) public {
        require(msg.sender == generalRepo[contractId].payer ||
            msg.sender == generalRepo[contractId].payee, "You are not involved in this contract!");
        generalRepo[contractId].isSigned = generalRepo[contractId].isSigned.add(1);
        // Todo
    }

    function isSigned(uint256 contractId) public view returns (bool) {
        return generalRepo[contractId].isSigned == 2;
    }

    function isVerified(uint256 contractId) public view returns (bool) {
        return generalRepo[contractId].isVerified == ContractUtility.getVerifierAmount();
    }

    function addToContractRepo(address contractAddress, ContractUtility.ContractType contractType, 
        ContractUtility.Consensus consensus, ContractUtility.DisputeType dispute, 
        address payer, address payee) public returns (uint256) {
        counter.add(1);
        idToAddressRepo[contractAddress] = counter;
        generalRepo[counter] = BasicProperties(
            counter,
            contractType, 
            consensus,
            dispute,
            DisputeMechanism(address(0)),
            payer,
            ContractUtility.Signature(0, 0, 0),
            payee,
            ContractUtility.Signature(0, 0, 0),
            0,
            0
        );
        return counter;
    }
}
