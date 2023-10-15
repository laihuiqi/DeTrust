// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ContractUtility.sol";
import "./BaseContract.sol";

/**
 * @title CommonContract
 * @dev This contract is used for widely customisable contracts.
 *
 * It allows for the creation of contracts with multiple obligations.
 */
contract CommonContract {
    using SafeMath for uint256;
    
    BaseContract public base;
    uint256 contractId;
    ContractUtility.Common public common;
    address payable initiator; // set to the first payee
    address payable respondent; // set to the first payer
    uint256 totalObligations = 0; 
    bool[] obligationsDone; // set to true when obligation is done by payer
    bool[] obligationsVerified; // set to true when done obligation is verified by payee

    event ContractCreated(address indexed _contract, uint256 indexed _contractId);
    event ObligationDone(uint256 indexed _obligationId);
    event ObligationVerified(uint256 indexed _obligationId);
    event ContractEnded(address indexed _contract, uint256 indexed _contractId);

    modifier contractReady() {
        require(base.isContractReady(contractId), "Contract is not ready!");
        _;
    }

    constructor(BaseContract _base, address payable[] memory _payers, address payable[] memory _payees,
        string memory _title, string memory _contractType, string[] memory _obligationTitles, 
        string[] memory _obligationDescriptions, uint256[] memory _paymentAmounts, uint256 _totalObligations, 
        ContractUtility.DisputeType _dispute) payable {

        // check if all obligation arrays have the same length
        require(_totalObligations == _obligationTitles.length, 
            "Total obligations does not match obligation titles!");
        require(_totalObligations == _obligationDescriptions.length, 
            "Total obligations does not match obligation descriptions!");
        require(_totalObligations == _paymentAmounts.length, 
            "Total obligations does not match payment amounts!");

        base = _base;
        initiator = _payees[0];
        respondent = _payers[0];
        totalObligations = _totalObligations;

        // create common contract instance
        common = ContractUtility.Common(
            _title,
            _contractType,
            initiator,
            respondent,
            _obligationTitles,
            _obligationDescriptions,
            _paymentAmounts,
            _payers,
            _payees
        );

        // store contract in repo
        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.COMMON,
            _dispute, initiator, respondent);

        emit ContractCreated(address(this), contractId);
    }

    // verify if the function caller is one of the payer
    // accessible from other contract
    function isPayer(address caller) public view returns (bool) {
        for (uint256 i = 0; i < common.payer.length; i++) {
            if (caller == common.payer[i]) {
                return true;
            }
        }
        return false;
    }

    // verify if the function caller is one of the payee
    // accessible from other contract
    function isPayee(address caller) public view returns (bool) {
        for (uint256 i = 0; i < common.payee.length; i++) {
            if (caller == common.payee[i]) {
                return true;
            }
        }
        return false;
    }

    // resolve obligation with _obligationId by paying the correct amount
    // obligation is done by any payer
    function resolveObligation(uint256 _obligationId) public payable contractReady {
        require(isPayer(msg.sender), "You are not the payer!");
        require(msg.value == common.paymentAmount[_obligationId], 
            "You have not paid the correct amount!");
        
        obligationsDone[_obligationId] = true;

        emit ObligationDone(_obligationId);
    }

    // verify a done obligation with _obligationId by the payee
    // verification is done by any payee
    function verifyObligationDone(uint256 _obligationId) public contractReady {
        require(isPayee(msg.sender), "You are not the payee!");
        require(obligationsDone[_obligationId], "Obligation is not done yet!");
        
        obligationsVerified[_obligationId] = true;

        emit ObligationVerified(_obligationId);
    }

    // check if an obligation with _obligationId is done or verified
    function checkObligationState(uint256 _obligationId) public view returns (bool, bool) {
        return (obligationsDone[_obligationId], obligationsVerified[_obligationId]);
    }

    // check if all obligations are done and verified
    function checkContractState() public view returns (bool, bool) {
        uint256 done = 0;
        uint256 verified = 0;

        for (uint256 i = 0; i < totalObligations; i++) {
            if (obligationsDone[i]) {
                done = done.add(1);
            }
            if (obligationsVerified[i]) {
                verified = verified.add(1);
            }
        }
        return (done == totalObligations, verified == totalObligations);
    }

    // end contract and destruct the contract instance
    // contract is ended by any involved party
    // all the obligations should be done and verified before ending the contract
    function endContract() public {
        require(msg.sender == initiator || msg.sender == respondent, 
            "You are not involved in this contract!");
        (bool done, bool verified) = checkContractState();
        require(done, "Contract is not done yet!");
        require(verified, "Contract is not verified yet!");

        base.completeContract(contractId);

        emit ContractEnded(address(this), contractId);
        
        selfdestruct(payable(address(this)));
    }
}