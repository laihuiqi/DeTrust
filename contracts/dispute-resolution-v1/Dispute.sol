// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "../TrustScore.sol";

contract Dispute {
    // Basic variables
    address initiator;
    address respondent;
    string title;
    string description;
    Status disputeStatus;

    // Dispute Outcomes
    Outcome initiatorOutcome;
    Outcome respondentOutcome;
    Outcome finalOutcome;

    // TrustScore related variables
    TrustScore trustScoreContract;
    uint256 trustScoreRequired;
    mapping(TrustScore.TrustTier => TrustScore.Range) trustScoreAmounts;
    VoteSum initiatorVoteSum;
    Vote[] initiatorVotes;
    VoteSum respondentVoteSum;
    Vote[] respondentVotes;
    LossGain loseGainAmounts;

    enum Status {
        INITIATED,
        CANCELLED,
        VOTING,
        CLOSED,
        RESOLVED
    }

    struct Outcome {
        bool isValid;
        address userAddress;
        string outcomeDescription;
    }

    struct VoteSum {
        uint256 time;
        uint256 score;
        uint256 prevScore;
    }

    struct Vote {
        address user;
        uint256 score;
    }

    struct LossGain {
        uint256 partyGain;
        uint256 partyLoss;
        uint256 voterGain;
    }

    constructor(
        TrustScore trustScoreAddress,
        address respondent_,
        string memory title_,
        string memory description_
    ) {
        trustScoreContract = trustScoreAddress;
        initiator = msg.sender;
        respondent = respondent_;
        title = title_;
        description = description_;
        disputeStatus = Status.INITIATED;

        trustScoreRequired = 500;
        trustScoreAmounts[TrustScore.TrustTier.HIGHLYTRUSTED] = TrustScore
            .Range(5, 10);
        trustScoreAmounts[TrustScore.TrustTier.TRUSTED] = TrustScore.Range(
            5,
            8
        );
        trustScoreAmounts[TrustScore.TrustTier.NEUTRAL] = TrustScore.Range(
            5,
            5
        );

        loseGainAmounts = LossGain(20, 20, 2);
    }

    function submitOutcome(string memory outcome) public {
        require(disputeStatus == Status.INITIATED);
        require(msg.sender == initiator || msg.sender == respondent);

        Outcome memory userOutcome = Outcome(true, msg.sender, outcome);

        if (msg.sender == initiator) {
            initiatorOutcome = userOutcome;
        } else {
            respondentOutcome = userOutcome;
        }
    }

    // Submit vote
    // - status has to be in VOTING
    // - UNTRUSTED users cannot vote
    // - trust score staked must be within the range
    function vote(bool choice, uint256 score) public {
        require(disputeStatus == Status.VOTING);
        require(
            trustScoreContract.getTrustTier(msg.sender) !=
                TrustScore.TrustTier.UNTRUSTED
        );

        TrustScore.Range memory range = trustScoreAmounts[
            trustScoreContract.getTrustTier(msg.sender)
        ];

        require(score >= range.floor && score <= range.ceil);

        // Choice: true for initiator, false for respondent
        // Close voting if vote hits minimum trust score required
        if (choice) {
            initiatorVotes.push(Vote(msg.sender, score));
            initiatorVoteSum = VoteSum(
                block.timestamp,
                initiatorVoteSum.score + score,
                initiatorVoteSum.score
            );
            if (initiatorVoteSum.score >= trustScoreRequired) {
                closeVoting();
            }
        } else {
            respondentVotes.push(Vote(msg.sender, score));
            respondentVoteSum = VoteSum(
                block.timestamp,
                respondentVoteSum.score + score,
                respondentVoteSum.score
            );
            if (respondentVoteSum.score >= trustScoreRequired) {
                closeVoting();
            }
        }
    }

    function cancelDispute() public {
        require(msg.sender == initiator);
        disputeStatus = Status.CANCELLED;
    }

    function openVoting() public {
        require(disputeStatus == Status.INITIATED);
        require(initiatorOutcome.isValid && respondentOutcome.isValid);
        disputeStatus = Status.VOTING;
        uint256 time = block.timestamp;
        initiatorVoteSum = VoteSum(time, 0, 0);
        respondentVoteSum = VoteSum(time, 0, 0);
    }

    function closeVoting() internal {
        require(disputeStatus == Status.VOTING);
        disputeStatus = Status.CLOSED;
    }

    function concludeVotes() public {
        require(disputeStatus == Status.CLOSED);

        // Check which vote is higher
        bool initiatorWin;

        if (initiatorVoteSum.score != respondentVoteSum.score) {
            initiatorWin = (initiatorVoteSum.score > respondentVoteSum.score);
        } else {
            // Tiebreak by earlier vote time
            if (initiatorVoteSum.time != respondentVoteSum.time) {
                initiatorWin = (initiatorVoteSum.time < respondentVoteSum.time);
            } else {
                // if same time, tiebreak with previous scores
                initiatorWin = (initiatorVoteSum.prevScore >
                    respondentVoteSum.prevScore);
            }
        }

        finalOutcome = initiatorWin ? initiatorOutcome : respondentOutcome;
        disputeStatus = Status.RESOLVED;

        // Increase and Decrease trust scores for all parties and voters
        if (initiatorWin) {
            trustScoreContract.increaseTrustScore(
                initiator,
                loseGainAmounts.partyGain
            );

            trustScoreContract.decreaseTrustScore(
                respondent,
                loseGainAmounts.partyLoss
            );

            for (uint i = 0; i < initiatorVotes.length; i++) {
                trustScoreContract.increaseTrustScore(
                    initiatorVotes[i].user,
                    loseGainAmounts.voterGain
                );
            }

            for (uint j = 0; j < respondentVotes.length; j++) {
                trustScoreContract.decreaseTrustScore(
                    respondentVotes[j].user,
                    respondentVotes[j].score
                );
            }
        } else {
            trustScoreContract.increaseTrustScore(
                respondent,
                loseGainAmounts.partyGain
            );

            trustScoreContract.decreaseTrustScore(
                initiator,
                loseGainAmounts.partyLoss
            );

            for (uint x = 0; x < respondentVotes.length; x++) {
                trustScoreContract.increaseTrustScore(
                    respondentVotes[x].user,
                    loseGainAmounts.voterGain
                );
            }

            for (uint y = 0; y < initiatorVotes.length; y++) {
                trustScoreContract.decreaseTrustScore(
                    initiatorVotes[y].user,
                    respondentVotes[y].score
                );
            }
        }
    }

    function getTitle() public view returns (string memory) {
        return title;
    }

    function getDescription() public view returns (string memory) {
        return description;
    }

    function getDisputeStatus() public view returns (Status) {
        return disputeStatus;
    }

    function getFinalOutcome() public view returns (string memory) {
        return finalOutcome.outcomeDescription;
    }
}
