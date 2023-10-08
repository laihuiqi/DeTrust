// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../DisputeMechanism.sol";
import "../DeTrustToken.sol";
import "./intellectual-property/LicenseOwningContract.sol";

library ContractUtility {
    enum Consensus {
        NEW,
        PENDING,
        PASS,
        FAIL
    }

    enum ContractType {
        FUTURE,
        OPTION,
        BOND,
        FUND,
        STOCK,
        LEND_BORROW_DTR,
        LEND_BORROW_ETH,
        SIMPLE_PAYMENT,
        SMART_VOUCHER,
        CONTENT_LICENSING,
        LEASE,
        PURCHASE,
        SERVICE
    }

    enum DisputeType {
        NONE,
        ARBITRATION,
        MEDIATION,
        ESCROW,
        JURY
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum ObjectType { TOKEN, NFT }
    enum DerivativeState{ PENDING, ACTIVE, EXPIRED }

    struct Future {
        DeTrustToken deTrustToken;
        address seller;
        address buyer;
        DerivativeState state;
        ObjectType assetType;
        IERC20 asset_token;
        IERC721 asset_nft;
        uint256 assetCode;
        uint256 quantity;
        uint256 deliveryDate;
        uint256 futurePrice;
        uint256 margin;
        uint256 premium;
        bool isHold;
        string description;
    }

    enum OptionType { CALL, PUT }

    struct Option {
        DeTrustToken deTrustToken;
        address optionSeller; // short position
        address optionBuyer; // long position
        DerivativeState state;
        OptionType optionType;
        ObjectType assetType;
        uint256 assetCode;
        IERC20 asset_token;
        IERC721 asset_nft;
        uint256 quantity;
        uint256 deliveryDate;
        uint256 strikePrice;
        uint256 optionPremium;
        uint256 margin;
        bool isHold;
    }

    enum SecuritiesState { ISSUED, ACTIVE, REDEEMED }

    struct Bond {
        DeTrustToken deTrustToken;
        address issuer;
        address owner;
        string bondName;
        string bondCode;
        SecuritiesState state;
        uint256 quantity;
        uint256 issueDate;
        uint256 maturity;
        uint256 couponRate;
        uint256 couponPaymentInterval;
        uint256 bondPrice;
        uint256 faceValue;
        uint256 redemptionValue;
        uint256 couponPaymentDate;
        uint256 cummulativeCoupon;
        bool isRedemptionReady;
    }

    struct Fund {
        DeTrustToken deTrustToken;
        string fundName;
        string fundDescription;
        address fundManager;
        address fundHolder;
        SecuritiesState state;
        uint256 fundValue;
        uint256 fundShares;
        uint256 yieldRate;
        uint256 interestInterval;
        uint256 commisionRate;
        uint256 interestPaymentDate;
        uint256 cummulativeYieldCount;
    }

    struct Stock {
        DeTrustToken deTrustToken;
        address issuer;
        address shareholder;
        string stockName;
        string stockCode;
        SecuritiesState state;
        uint256 stockValue;
        uint256 shares;
        uint256 dividenRate;
        uint256 dividenPaymentInterval;
        uint256 dividenPaymentDate;
        uint256 dividenCount;
    }

    struct LendBorrow {
        DeTrustToken deTrustToken;
        address borrower;
        address lender;
        uint256 contractDuration; 
        uint256 creationCost;
        uint256 amount; 
        uint256 releaseTime; 
        uint256 interestRate;
        bool isLended;
        bool isBorrowed;
        bool isRepaid;
        bool isRetrieved;
    }

    struct SimplePayment {
        DeTrustToken deTrustToken;
        address payer;
        address payee;
        uint256 amount;
        uint256 paymentDate;
        string description;
        bool isPaid;
        bool isWithdrawn;
    }

    enum VoucherType { DISCOUNT, GIFT }
    enum VoucherState { ACTIVE, REDEEMED }

    struct SmartVoucher {
        address issuer;
        address redeemer;
        address usageAddress;
        string description;
        VoucherType voucherType;
        VoucherState state;
        uint256 value;
        uint256 expiryDate;
    } 

    enum LicenseState{ PENDING, ACTIVE, EXPIRED }

    struct ContentLicensing {
        DeTrustToken deTrustToken;
        address owner;
        address licensee;
        LicenseOwningContract license;
        LicenseState state;
        uint256 price;
        uint256 startDate;
        uint256 endDate;
        uint256 payment;
        bool terminating;
    }

    enum LeaseState { PENDING, ACTIVE, TERMINATED }

    struct Lease {
        DeTrustToken deTrustToken;
        address landlord;
        address tenant;
        string description;
        LeaseState state;
        uint256 startDate;
        uint256 endDate;
        uint256 paymentDate;
        uint256 rent;
        uint256 deposit;
        uint256 occupancyLimit;
        uint256 stampDuty;
        uint256 paymentCount;
    }
    
    struct Purchase {
        DeTrustToken deTrustToken;
        address seller;
        address buyer;
        string description;
        uint256 price;
        uint256 paymentDate;
        uint256 deliveryDate;
        bool isReceived;
        bool isPaid;
    }

    enum ServiceType { FREELANCE, SUBCRIPTION }

    struct Service {
        DeTrustToken deTrustToken;
        ServiceType serviceType;
        address serviceProvider;
        address client;
        uint256 contractDuration;
        string description;
        uint256 paymentTerm;
        uint256 singlePayment;
        uint256 paymentDate;
        uint256 paymentCount;
    }

    function getContractCost() public pure returns (uint256) {
        // dependes on contract type and user tier
        return 500;
    }

    function getVerifierAmount() public pure returns (uint256) {
        // depends on user tier
        return 5;
    }
}