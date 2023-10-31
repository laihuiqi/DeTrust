// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../DeTrustToken.sol";
import "../TrustScore.sol";
import "./ContractUtility.sol";
import "../dispute-resolution-v1/Dispute.sol";
import "./CommonContract.sol";

/**
 * @title BaseContract
 * @dev This contract is used for contracts logging and providing common functions after contract 
        creation.
 *
 * It allows to keep track of contract history, signing, verification, and chat communication.
 */
contract BaseContract {
    using SafeMath for uint256;

    address payable owner;
    TrustScore trustScore; // add trust score instance for updating trust score
    DeTrustToken deTrustToken;

    uint256 counter = 0;
    uint256 minimumTimeFrame = 1 days;
    uint256 verificationCutOffTime = 2 days;

    constructor(TrustScore _trustScore, DeTrustToken _deTrustToken) {
        owner = payable(address(msg.sender));
        trustScore = _trustScore;
        deTrustToken = _deTrustToken;
    }

    mapping(address => uint256) public addressToIdRepo;
    mapping(uint256 => address) public idToAddressRepo;
    mapping(uint256 => ContractUtility.BasicProperties) public generalRepo;
    mapping(uint256 => address[]) contractVerifyList;
    mapping(uint256 => address[]) contractFraudList;
    mapping(uint256 => Dispute) disputeRepo;
    mapping(address => address) walletMapping;
    mapping(uint256 => string[]) messageLog;
    
    event ContractLogged(address indexed _contract, uint256 indexed _contractId);
    event ContractSigned(uint256 indexed _contractId, address indexed _signer);
    event ContractVerified(uint256 indexed _contractId, address indexed _verifier);
    event VerificationResolved(uint256 indexed _contractId, ContractUtility.VerificationState _vstate);
    event MessageSent(uint256 indexed _contractId, address indexed _sender);

    modifier ownerOnly() {
        require(msg.sender == owner, "Your are not the owner!");
        _;
    }

    modifier notFreeze(uint256 _contractId) {
        require(generalRepo[_contractId].state != ContractUtility.ContractState.DISPUTED &&
            generalRepo[_contractId].state != ContractUtility.ContractState.COMPLETED &&
            generalRepo[_contractId].state != ContractUtility.ContractState.VOIDED, "Contract is inactivated!");
            _;
    }

    function ownerWithdraw() external ownerOnly {
        owner.transfer(address(this).balance);
    }

    // modifier to check if correct price is paid on contract payment
    modifier creationEligibility(address _payee, address _payer, address _walletPayee, 
        address _walletPayer) {
        uint256 amountPayee = ContractUtility.getContractCost(trustScore.getTrustTier(_payee));
        uint256 amountPayer = ContractUtility.getContractCost(trustScore.getTrustTier(_payer));

        require(trustScore.getTrustScore(_payee) >= 2, "Insufficient trust score for initiator!");
        require(trustScore.getTrustScore(_payer) >= 2, "Insufficient trust score for respondent!");
        require(deTrustToken.balanceOf(_walletPayee) >= amountPayee, "Insufficient trust score for initiator!");
        require(deTrustToken.balanceOf(_walletPayer) >= amountPayer, "Insufficient trust score for respondent!");
        
        deTrustToken.transferFrom(_walletPayee, address(this), amountPayee);
        deTrustToken.transferFrom(_walletPayer, address(this), amountPayer);
        _;
    }

    // modifier to check if the sender is involved in the contract
    modifier onlyInvolved(uint256 _contractId) {
        require(msg.sender == generalRepo[_contractId].signature.payer ||
            msg.sender == generalRepo[_contractId].signature.payee ||
            msg.sender == idToAddressRepo[_contractId], 
            "You are not involved in this contract!");
        _;
    }

    // contract history functions
    // add contract to repo
    function addToContractRepo(ContractUtility.ContractRepoInput memory repoInput) public 
        creationEligibility(repoInput._payee, repoInput._payer, repoInput._walletPayee, repoInput._walletPayer) 
        returns (uint256) {
        
        counter = counter.add(1);

        // map cotract address to contract id
        addressToIdRepo[repoInput._contractAddress] = counter;
        idToAddressRepo[counter] = repoInput._contractAddress;

        walletMapping[repoInput._payee] = repoInput._walletPayee;
        walletMapping[repoInput._payer] = repoInput._walletPayer;

        
        ContractUtility.Signature memory signature = ContractUtility.Signature(
            repoInput._payer,
            bytes32(0),
            repoInput._payee,
            bytes32(0),
            0
        );
        
        // create a relative instance of basic properties for the contract and store it in repo
        generalRepo[counter] = ContractUtility.BasicProperties(
            counter,
            ContractUtility.ContractState.DRAFT,
            block.timestamp,
            repoInput._contractType, 
            repoInput._dispute,
            signature,
            ContractUtility.VerificationState.PENDING,
            ContractUtility.getVerifierAmount(trustScore.getTrustTier(repoInput._payer)) 
                + ContractUtility.getVerifierAmount(trustScore.getTrustTier(repoInput._payee)),
            0,
            0
        );
        
        emit ContractLogged(repoInput._contractAddress, counter);

        // return contract id to the respective contract
        return counter;
    }

    // proceed a contract
    function proceedContract(uint256 _contractId) public onlyInvolved(_contractId) notFreeze(_contractId) {
        require(generalRepo[_contractId].isVerified == ContractUtility.VerificationState.LEGITIMATE, 
            "The contract is not verified!");
        generalRepo[_contractId].state = ContractUtility.ContractState.INPROGRESS;
    }

    // complete a contract
    function completeContract(uint256 _contractId) public onlyInvolved(_contractId) {
        generalRepo[_contractId].state = ContractUtility.ContractState.COMPLETED;

        trustScore.increaseTrustScore(generalRepo[_contractId].signature.payer, 
            ContractUtility.getContractCompletionReward(
                trustScore.getTrustTier(generalRepo[_contractId].signature.payer)));

        trustScore.increaseTrustScore(generalRepo[_contractId].signature.payee, 
            ContractUtility.getContractCompletionReward(
                trustScore.getTrustTier(generalRepo[_contractId].signature.payee)));
    }

    // void a contract
    function voidContract(uint256 _contractId) public onlyInvolved(_contractId) {
        generalRepo[_contractId].state = ContractUtility.ContractState.VOIDED;
    }

    // dispute a contract
    function disputeContract(uint256 _contractId, Dispute disputeAddress) public onlyInvolved(_contractId) {
        generalRepo[_contractId].state = ContractUtility.ContractState.DISPUTED;
        disputeRepo[_contractId] = disputeAddress;
    }

    // check if a contract is ready
    function isContractReady(uint256 _contractId) public view returns (bool) {
        return generalRepo[_contractId].state == ContractUtility.ContractState.INPROGRESS;
    }

    // contract signing functions

    // check if the contract is signed by both parties
    modifier isSigned(uint256 _contractId) {
        require(generalRepo[_contractId].signature.isSigned == 2, "Contract is not signed by both parties!");
        _;
    }

    // get message hash for signing
    function getMessageHash(address _signer, uint256 _contractId, uint _nonce, 
        uint8 _v, bytes calldata _r, bytes calldata  _s) public pure returns (bytes32) {
        
        return keccak256(abi.encodePacked(_signer, 
            keccak256(abi.encodePacked(_contractId,
            keccak256(abi.encodePacked('VERIFY')), 
            keccak256(abi.encodePacked(_v, _r, _s)), _nonce))));
    }

    // sign the contract with message hash
    function sign(uint256 _contractId, uint _nonce, uint8 _v, bytes calldata _r, bytes calldata _s) 
        public onlyInvolved(_contractId) notFreeze(_contractId) {

        bytes32 messageHash = getMessageHash(msg.sender, _contractId, _nonce, _v, _r, _s);
        
        if (msg.sender == generalRepo[_contractId].signature.payer) {
            require(generalRepo[_contractId].signature._ad1 == bytes32(0), 
                "You have already signed this contract!");
            generalRepo[_contractId].signature._ad1 = messageHash;

        } else {
            require(generalRepo[_contractId].signature._ad2 == bytes32(0), 
                "You have already signed this contract!");
            generalRepo[_contractId].signature._ad2 = messageHash;
        }

        generalRepo[_contractId].signature.isSigned = generalRepo[_contractId].signature.isSigned + 1;

        emit ContractSigned(_contractId, msg.sender);
    }

    // verify the signature of the contract
    // need to be verify if there is a dispute only
    function verifySignature(address _signer, uint256 _contractId, uint _nonce, 
        uint8 _v, bytes calldata _r, bytes calldata _s) public view returns (bool) {

        bytes32 messageHash = getMessageHash(_signer, _contractId, _nonce, _v, _r, _s);

        if (_signer == generalRepo[_contractId].signature.payer) {
            return generalRepo[_contractId].signature._ad1 == messageHash;
        } else {
            return generalRepo[_contractId].signature._ad2 == messageHash;
        }

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
        require(generalRepo[_contractId].isVerified == ContractUtility.VerificationState.PENDING, 
            "Contract is already verified!");

        require(block.timestamp - generalRepo[_contractId].creationTime <= verificationCutOffTime, 
            "Verification time is over!");

        bool verifierExceeded = block.timestamp - generalRepo[_contractId].creationTime > minimumTimeFrame && 
                generalRepo[_contractId].legitAmount.add(generalRepo[_contractId].fraudAmount) < 
                generalRepo[_contractId].verifierNeeded;

        require(block.timestamp - generalRepo[_contractId].creationTime <= minimumTimeFrame ||
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
        require(generalRepo[_contractId].isVerified == ContractUtility.VerificationState.PENDING, 
            "Contract is not available for verification!");

        require(block.timestamp - generalRepo[_contractId].creationTime > verificationCutOffTime ||
            (block.timestamp - generalRepo[_contractId].creationTime > minimumTimeFrame &&
            (generalRepo[_contractId].legitAmount.add(generalRepo[_contractId].fraudAmount) >= 
                generalRepo[_contractId].verifierNeeded)), 
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

        require(msg.sender != generalRepo[_contractId].signature.payer && 
            msg.sender != generalRepo[_contractId].signature.payee, 
            "You are involved in this contract!");

        if (generalRepo[_contractId].contractType == ContractUtility.ContractType.COMMON) {
            CommonContract common = CommonContract(idToAddressRepo[_contractId]);
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
        
        walletMapping[msg.sender] = _wallet;
        
        if(_vstate == ContractUtility.VerificationState.LEGITIMATE) {
            contractVerifyList[_contractId].push(msg.sender);
            generalRepo[_contractId].legitAmount = generalRepo[_contractId].legitAmount.add(1);
        } else {
            contractFraudList[_contractId].push(msg.sender);
            generalRepo[_contractId].fraudAmount = generalRepo[_contractId].fraudAmount.add(1);
        }

        deTrustToken.mintFor(_wallet, 10);

        emit ContractVerified(_contractId, msg.sender);

        if (block.timestamp - generalRepo[_contractId].creationTime > minimumTimeFrame) {
            if (generalRepo[_contractId].legitAmount >= generalRepo[_contractId].verifierNeeded / 2) {
                generalRepo[_contractId].isVerified = ContractUtility.VerificationState.LEGITIMATE;
                return ContractUtility.VerificationState.LEGITIMATE;

            } else if (generalRepo[_contractId].fraudAmount >= generalRepo[_contractId].verifierNeeded / 2) {
                generalRepo[_contractId].isVerified = ContractUtility.VerificationState.FRAUDULENT;
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
        isSigned(_contractId) verificationCanBeResolved(_contractId)  {

        if (generalRepo[_contractId].isVerified == ContractUtility.VerificationState.PENDING) {
            if (generalRepo[_contractId].legitAmount >= generalRepo[_contractId].fraudAmount) {
                generalRepo[_contractId].isVerified = ContractUtility.VerificationState.LEGITIMATE;
            } else {
                generalRepo[_contractId].isVerified = ContractUtility.VerificationState.FRAUDULENT;
            }
        }

        if (generalRepo[_contractId].isVerified == ContractUtility.VerificationState.LEGITIMATE) {
            proceedContract(_contractId);

            for (uint256 i = 0; i < contractFraudList[_contractId].length; i++) {
                deTrustToken.burnFor(walletMapping[contractFraudList[_contractId][i]], 100);
                trustScore.decreaseTrustScore(contractFraudList[_contractId][i], 1);
            }
            
        } else {
            voidContract(_contractId);
            
            deTrustToken.burnFor(walletMapping[generalRepo[_contractId].signature.payer], 500);
            deTrustToken.burnFor(walletMapping[generalRepo[_contractId].signature.payee], 500);
            trustScore.decreaseTrustScore(generalRepo[_contractId].signature.payer, 2);
            trustScore.decreaseTrustScore(generalRepo[_contractId].signature.payee, 2);

            for (uint256 i = 0; i < contractVerifyList[_contractId].length; i++) {
                deTrustToken.burnFor(walletMapping[contractVerifyList[_contractId][i]], 100);
                trustScore.decreaseTrustScore(contractVerifyList[_contractId][i], 1);
            }
        }

        emit VerificationResolved(_contractId, generalRepo[_contractId].isVerified);
    }

    // chat communication functions

    // involvers (initiator and respondent in the case of common contract) can send message to each other
    function sendMessage(uint256 _contractId, string memory _message) 
        public onlyInvolved(_contractId) notFreeze(_contractId) {
        
        // label each message string with the sender
        if (msg.sender == generalRepo[_contractId].signature.payer) {
            messageLog[_contractId].push(string(abi.encodePacked('Payer', ': ', _message)));
        } else {
            messageLog[_contractId].push(string(abi.encodePacked('Payee', ': ', _message)));
        }

        emit MessageSent(_contractId, msg.sender);
        
    }

    // get all messages in the message log for a certain contract by invlovers only
    function retriveMessage(uint256 _contractId) public view 
        onlyInvolved(_contractId) notFreeze(_contractId) returns (string memory) {
        string memory messages = "";

        // concatenate all messages in the message log
        for (uint i = 0; i < messageLog[_contractId].length; i++) {
            messages = string(abi.encodePacked(messages, messageLog[_contractId][i], '\n'));
        }

        return messages;
    }

}
