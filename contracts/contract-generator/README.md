# Contract generator for DeTrust

`Contract generator` contracts directory that act as blueprints to create various type of transaction 
related contracts.

>**_Note_**
>
> This project / contracts are still under development.

#### [Base Contract]()
Contract that acts as a repository to store generated contracts.
- General functions to retrive a contract properties or details are provided.
- Unique ids are given to each of the contracts to ease contract lookups.

#### [Contract Utility]()
Library to provide common constant data and structures.
- Enum:
  
  1. Consensus
  2. ContractType
  3. DisputeType
  4. ContractStructures

#### [Financial Contract]()
Provides contracts regarding following financial services:
1. Investment
   - Future
     -- Speculating on the future price of an asset by trading futures contracts.
   - Option
     -- Involves buying or selling options contracts, which give the holder the right (but not the obligation) to buy or sell an asset at a predetermined price.
   - Bond
   - Mutual fund
     -- Investing in funds that hold a diversified portfolio of stocks or bonds.
   - Stock
2. Lending borrowing
   - DTR
   - ETH
3. Simple payment
   -- Allow making simple payments.
4. Smart Voucher
   -- Create and redeem digital vouchers or tokens.

#### [Intellectual properties]()
Supports content licensing.

#### [Purchase agreement]()
Contracts aim to record and execute purchasing, trading and leasing functions.

#### [Service contract]()
Provides contracts for freelances, subscriptions and employments.
