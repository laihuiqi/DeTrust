// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "./UserProfiles.sol";

contract BaseContract {
    address private promisor;
    address private promisee;
    string private _name;
    Consensus private _consensus = Consensus.NEW;

    enum Consensus {
        NEW,
        PENDING,
        PASS,
        FAIL
    }

    mapping(address => int256) private votesScore;
    uint256 private votesCount;
    int256 private contractScore;

    UserProfiles userProfilesContract;

    constructor(UserProfiles userProfilesAddress, string memory name_) {
        userProfilesContract = userProfilesAddress;
        _name = name_;
        promisor = msg.sender;
    }

    modifier onlyOwner() {
        require(promisor == msg.sender);
        _;
    }

    modifier allowChanges() {
        require(_consensus == Consensus.NEW);
        _;
    }

    modifier allowVotes() {
        require(_consensus == Consensus.PENDING);
        _;
    }

    modifier externalParties() {
        require(msg.sender != address(0));
        require(promisor != msg.sender && promisee != msg.sender);
        _;
    }

    modifier canVote(address addr) {
        require(votesScore[addr] == 0);
        _;
    }

    function setPromisee(address addr) public onlyOwner allowChanges {
        promisee = addr;
        _consensus = Consensus.PENDING;
    }

    function vote(
        bool pass
    ) public allowVotes externalParties canVote(msg.sender) {
        // Get message sender's rep
        int256 rep = 10;

        int256 score = pass ? rep * 1 : rep * -1;

        votesScore[msg.sender] = score;
        contractScore += score;
        votesCount++;
    }
}
