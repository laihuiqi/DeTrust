# Contract generator for DeTrust

`Contract generator` contracts directory that act as blueprints to create various type of transaction 
related contracts.

#### [Base Contract](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/BaseContract.sol) 
Contract that acts as a repository to store generated contracts.
- General functions to retrive a contract properties or details are provided.
- Unique ids are given to each of the contracts to ease contract lookups.

#### [Contract Utility](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/ContractUtility.sol)
Library to provide common constant data and structures.
- Enum:
  
  1. Consensus
  2. ContractType
  3. DisputeType
 
- Structure:

  1. BasicProperties (For contracts)
 
#### [conditional-payments Directory](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments)
Implementations of contract blueprints that `is-a` conditional payment generally.
- [Simple payment](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments/SimplePayment.sol)
- [Escrow](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments/Escrow.spl)
- [Subscription](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments/Subscription.sol)
- [Fixed deposit](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments/FixedDeposit.sol)
- [Payment channel](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments/PaymentChannel.sol)
- [Smart voucher](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments/SmartVoucher.sol)
- [Trade agreement](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments/TradeAgreement.sol)
- [Cross-chain exchange](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/conditional-payments/CrossChainExchange.sol)

#### [Multi Signature Wallet](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/MultiSignatureWallet.sol)
Allow multiple parties to jointly control the funds held in the wallet.

#### [Lending Borrowing](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/LendBorrowContract.sol)
Lend asset(s) on predefined terms : Interest rates, repayment schedule.

#### [Token Exchange](https://github.com/laihuiqi/DeTrust/edit/contract-generator/contracts/contract-generator/TokenExchangeContract.sol)
Exchange one type of token to another at a specified rate.
