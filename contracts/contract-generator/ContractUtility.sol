// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../UserProfiles.sol";
import "../DisputeMechanism.sol";

library ContractUtility {
    enum Consensus {
        NEW,
        PENDING,
        PASS,
        FAIL
    }

    enum ContractType {
        SIMPLE_PAYMENT,
        MULTI_SIGNATURE_WALLET,
        LENDING_BORROWING,
        TOKEN_EX,
        CONDITIONAL_PAYMENT,
        ESCROW,
        PAYMENT_CHANNEL,
        SUBSCRIPTION,
        FD,
        TRADE_AGREEMENT,
        CROSS_CHAIN_EX,
        SMART_VOUCHER,
        LEND_BORROW_TOKEN
    }

    enum DisputeType {
        NONE,
        ARBITRATION,
        MEDIATION,
        ESCROW,
        JURY
    }

    struct BasicProperties {
        uint256 _id;
        address _contractAddress;
        UserProfiles _promisor;
        UserProfiles _promisee;
        Consensus _consensus;
        ContractType _contractType;
        uint256 _createdAt;
        uint256 _contractDuration;
        uint256 _currentCost;
        DisputeType _disputeType;
        DisputeMechanism _disputeMechanism;
    }
}