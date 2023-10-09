// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";
import "../../../ContractUtility.sol";
import "../../../BaseContract.sol";

contract MutualFundContract {
    using SafeMath for uint256;

    BaseContract public base;
    uint256 contractId;
    ContractUtility.Fund public fund;

    constructor(BaseContract _base, DeTrustToken _wallet, string memory _fundName, string memory _fundDescription, address _fundManager, 
        address _fundHolder, uint256 _fundValue, uint256 _fundShare, uint256 _yieldRate, uint256 _interestInterval, 
        uint256 _commisionRate, uint256 _firstInterestDate, ContractUtility.Consensus _consensus, 
        ContractUtility.DisputeType _dispute) {
    
        fund = ContractUtility.Fund(
            _wallet,
            _fundName,
            _fundDescription,
            _fundManager,
            _fundHolder,
            ContractUtility.SecuritiesState.ISSUED,
            _fundValue,
            _fundShare,
            _yieldRate,
            _interestInterval,
            _commisionRate,
            _firstInterestDate,
            0
        );

        base = _base;

        contractId = base.addToContractRepo(address(this), ContractUtility.ContractType.FUND,
            _consensus, _dispute, _fundManager, _fundHolder);

        _wallet.transfer(address(_base), ContractUtility.getContractCost());
    }

    function buy() public {
        // buy the fund
        require(base.isSigned(contractId), "Contract has not been signed!");
        require(base.isVerified(contractId), "Contract has not been verified!");
        require(fund.state == ContractUtility.SecuritiesState.ISSUED, "Fund should be issuing!");
        require(msg.sender == fund.fundHolder, "You are not the fund holder!");

        fund.deTrustToken.transfer(fund.fundManager, fund.fundValue.mul(fund.fundShares));
        fund.state = ContractUtility.SecuritiesState.ACTIVE;
    }

    function transfer(address _transferee) public {
        // sell the fund
        require(fund.state == ContractUtility.SecuritiesState.ACTIVE, "Fund should be active!");
        require(msg.sender == fund.fundHolder, "You are not the fund holder!");

        fund.fundHolder = _transferee;
    }

    function payYield() public {
        // pay interest to the fund holders
        require(fund.state == ContractUtility.SecuritiesState.ACTIVE, "Fund should be active!");
        require(msg.sender == fund.fundManager, "Only fund manager can pay interest!");
        require(block.timestamp >= fund.interestPaymentDate, "Interest payment date has not reached!");
    
        fund.deTrustToken.approve(fund.fundHolder, 
            fund.fundValue.mul(fund.fundShares).mul(fund.yieldRate.sub(fund.commisionRate)).div(100));
        fund.interestPaymentDate = fund.interestPaymentDate.add(fund.interestInterval);
        fund.cummulativeYieldCount = fund.cummulativeYieldCount.add(1);
    }

    function redeemInterest() public {
        // redeem the interest
        require(fund.state == ContractUtility.SecuritiesState.ACTIVE, "Fund should be active!");
        require(msg.sender == fund.fundHolder, "You are not the fund holder!");
        require(fund.cummulativeYieldCount > 0, "No interest to redeem!");

        fund.cummulativeYieldCount = 0;
        fund.deTrustToken.transferFrom(fund.fundManager, fund.fundHolder,
            fund.fundValue.mul(fund.fundShares).mul(fund.commisionRate).mul(fund.cummulativeYieldCount).div(100));
    }

    function updateYieldRate(uint256 _newYieldRate) public {
        // update the yield rate
        require(msg.sender == fund.fundManager, "Only fund manager can update yield rate!");

        fund.cummulativeYieldCount = _newYieldRate;
    }

    function updateCommisionRate(uint256 _newCommisionRate) public {
        // update the commision rate
        require(msg.sender == fund.fundManager, "Only fund manager can update commision rate!");

        fund.commisionRate = _newCommisionRate;
    }

    function terminateFundContract() public {
        require(msg.sender == fund.fundHolder, "Only fund holder can terminate the fund contract!");

        fund.state = ContractUtility.SecuritiesState.REDEEMED;
        selfdestruct(payable(address(this)));
    }
}