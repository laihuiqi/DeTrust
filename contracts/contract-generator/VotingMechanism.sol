// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ContractUtility.sol";
import "./BaseContract.sol";
import "../DeTrustToken.sol";
import "../TrustScore.sol";

contract VotingMechanism {
    using SafeMath for uint256;

    BaseContract base;
    DeTrustToken deTrustToken;
    TrustScore trustScore;

    uint256 minimumTimeFrame = 1 days;
    uint256 verificationCutOffTime = 2 days;

    constructor(BaseContract _base, DeTrustToken _deTrustToken, TrustScore _trustScore) {
        base = _base;
        deTrustToken = _deTrustToken;
        trustScore = _trustScore;
    }

    mapping(uint256 => address[]) contractVerifyList;
    mapping(uint256 => address[]) contractFraudList;

    event ContractVerified(uint256 indexed _contractId, address indexed _verifier);
    event VerificationResolved(uint256 indexed _contractId, ContractUtility.VerificationState _vstate);

    modifier isSigned(uint256 _contractId) {
        require(base.isSigned(_contractId), "Contract is not completely signed yet!");
        _;
    }

    modifier notFreeze(uint256 _contractId) {
        require(base.isActive(_contractId), "The contract is inactivated!");
        _;
    }

    // verification functions

    /**
     * @dev Modifier to check if the verification time limit is passed.
     * @param _contractId The contract id to be verified.
     * 
     * Requirements:
        * The contract must be not verified.
        * The contract could be verified if the minimun verification time limit has not passed.
        * The contract could be verified if the minimun verification time limit has passed 
          and the verifier amount is not exceeded 
          and the maximum verification time limit has not passed.
     */
    modifier verifyAllowed(uint256 _contractId) {

        ContractUtility.BasicProperties memory properties = base.getGeneralRepo(_contractId);

        require(properties.isVerified == ContractUtility.VerificationState.PENDING, 
            "Contract is already verified!");

        require(block.timestamp - properties.creationTime <= verificationCutOffTime, 
            "Verification time is over!");

        bool verifierExceeded = block.timestamp - properties.creationTime > minimumTimeFrame && 
                properties.legitAmount.add(properties.fraudAmount) < 
                properties.verifierNeeded;

        require(block.timestamp - properties.creationTime <= minimumTimeFrame ||
            verifierExceeded, "Verifier amount exceeded!");

        _;
    }

    /**
     * @dev Modifier to check if the verification could be resolved.
     * 
     * Requirements:
        * The contract must be not verified.
        * The contract could be verified if the minimun verification time limit has passed
          and the verifier amount is reached or exceeded.
        * The contract could be verified if the maximum verification time limit has passed.
     */
    modifier verificationCanBeResolved(uint256 _contractId) {
        /*

        ContractUtility.BasicProperties memory properties = base.getGeneralRepo(_contractId);

        require(properties.isVerified == ContractUtility.VerificationState.PENDING, 
            "Contract is not available for verification!");

        require(block.timestamp - properties.creationTime > verificationCutOffTime ||
            (block.timestamp - properties.creationTime > minimumTimeFrame &&
            (properties.legitAmount.add(properties.fraudAmount) >= 
                properties.verifierNeeded)), 
            "Verification is not availble yet!");
            */
        _;
    }

    // verifier should not be involved in the contract
    modifier notInvolved(uint256 _contractId, address _wallet) {
        bool checkVoted = false;

        for (uint256 i = 0; i < contractVerifyList[_contractId].length; i++) {
            if (contractVerifyList[_contractId][i] == msg.sender) {
                require(checkVoted, "You have voted for this contract!");
            }
        }

        for (uint256 i = 0; i < contractFraudList[_contractId].length; i++) {
            if (contractFraudList[_contractId][i] == msg.sender) {
                require(checkVoted, "You have voted for this contract!");
            }
        }

        require(msg.sender != base.getGeneralRepo(_contractId).signature.payer && 
            msg.sender != base.getGeneralRepo(_contractId).signature.payee, 
            "You are involved in this contract!");

        if (base.getGeneralRepo(_contractId).contractType == ContractUtility.ContractType.COMMON) {
            CommonContract common = CommonContract(base.getAddressRepo(_contractId));
            require(!common.isPayer(msg.sender) && !common.isPayee(msg.sender), 
                "You are involved in this contract!");
        }

        require(trustScore.getTrustTier(msg.sender) != TrustScore.TrustTier.UNTRUSTED, 
            "Insufficient trust score!");
        require(deTrustToken.balanceOf(_wallet) >= 5, 
            "Insufficient token to vote!");
        _;
    }

    // verify the contract
    // contract can be verified by any address except involvers
    function verifyContract(uint256 _contractId, ContractUtility.VerificationState _vstate, 
        address _wallet) public notFreeze(_contractId) isSigned(_contractId) verifyAllowed(_contractId) 
        notInvolved(_contractId, _wallet) returns (ContractUtility.VerificationState) {
        
        base.setWalletMapping(msg.sender, _wallet);

        ContractUtility.BasicProperties memory properties = base.getGeneralRepo(_contractId);
        
        if(_vstate == ContractUtility.VerificationState.LEGITIMATE) {
            contractVerifyList[_contractId].push(msg.sender);
            properties.legitAmount = properties.legitAmount.add(1);
        } else {
            contractFraudList[_contractId].push(msg.sender);
            properties.fraudAmount = properties.fraudAmount.add(1);
        }

        base.setGeneralRepo(_contractId, properties);

        deTrustToken.mintFor(_wallet, 10);

        emit ContractVerified(_contractId, msg.sender);

        if (block.timestamp - properties.creationTime > minimumTimeFrame) {
            if (properties.legitAmount >= properties.verifierNeeded / 2) {
                properties.isVerified = ContractUtility.VerificationState.LEGITIMATE;
                base.setGeneralRepo(_contractId, properties);
                return ContractUtility.VerificationState.LEGITIMATE;

            } else if (properties.fraudAmount >= properties.verifierNeeded / 2) {
                properties.isVerified = ContractUtility.VerificationState.FRAUDULENT;
                base.setGeneralRepo(_contractId, properties);
                return ContractUtility.VerificationState.FRAUDULENT;
            }
        }
        
        return ContractUtility.VerificationState.PENDING;
    }

    /**
     * @dev Resolve the verification of the contract.
     * @param _contractId The contract id to be verified.
     *
     * Requirements:
        * The true verifier will be rewarded with 10 DTRs.
        * The false verifier will be deducted with 5 DTRs and 1 trust score.
        * FRAUDULENT:
            * The payer and the payee will be deducted with 500 DTRs and 2 trust scores.
     */
    function resolveVerification(uint256 _contractId) public notFreeze(_contractId) 
        isSigned(_contractId) verificationCanBeResolved(_contractId) {

        ContractUtility.BasicProperties memory properties = base.getGeneralRepo(_contractId);

        if (properties.isVerified == ContractUtility.VerificationState.PENDING) {
            if (properties.legitAmount >= properties.fraudAmount) {
                properties.isVerified = ContractUtility.VerificationState.LEGITIMATE;
            } else {
                properties.isVerified = ContractUtility.VerificationState.FRAUDULENT;
            }
        }

        base.setGeneralRepo(_contractId, properties);

        if (properties.isVerified == ContractUtility.VerificationState.LEGITIMATE) {
            base.proceedContract(_contractId);

            for (uint256 i = 0; i < contractFraudList[_contractId].length; i++) {
                deTrustToken.burnFor(base.getWalletAddress(contractFraudList[_contractId][i]), 100);
                trustScore.decreaseTrustScore(contractFraudList[_contractId][i], 1);
            }
            
        } else {
            base.voidContract(_contractId);
            
            deTrustToken.burnFor(base.getWalletAddress(properties.signature.payer), 500);
            deTrustToken.burnFor(base.getWalletAddress(properties.signature.payee), 500);
            trustScore.decreaseTrustScore(properties.signature.payer, 2);
            trustScore.decreaseTrustScore(properties.signature.payee, 2);

            for (uint256 i = 0; i < contractVerifyList[_contractId].length; i++) {
                deTrustToken.burnFor(base.getWalletAddress(contractVerifyList[_contractId][i]), 100);
                trustScore.decreaseTrustScore(contractVerifyList[_contractId][i], 1);
            }
        }

        emit VerificationResolved(_contractId, properties.isVerified);
    }
}