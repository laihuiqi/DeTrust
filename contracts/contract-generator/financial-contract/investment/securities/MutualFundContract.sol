// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../DeTrustToken.sol";

contract MutualFundContract {
    using SafeMath for uint256;

    enum FundState { Issued, Active, Terminated }
    DeTrustToken deTrustToken;

    string fundName;
    string fundDescription;
    address fundManager;
    address fundHolder;
    FundState state;
    uint256 fundValue;
    uint256 fundShares;
    uint256 yieldRate;
    uint256 interestInterval;
    uint256 commisionRate;
    uint256 interestPaymentDate;

    mapping(address => uint256) public fundShareholders;

    constructor(DeTrustToken _wallet, string memory _fundName, string memory _fundDescription, address _fundManager, 
        address _fundHolder, uint256 _fundValue, uint256 _fundShare, uint256 _yieldRate, uint256 _interestInterval, 
        uint256 _commisionRate, uint256 _firstInterestDate) {
        deTrustToken = _wallet;
        fundName = _fundName;
        fundDescription = _fundDescription;
        fundManager = _fundManager;
        fundHolder = _fundHolder;
        state = FundState.Issued;
        fundValue = _fundValue;
        fundShares = _fundShare;
        yieldRate = _yieldRate;
        interestInterval = _interestInterval;
        commisionRate = _commisionRate;
        interestPaymentDate = _firstInterestDate;
    }

    function buy() public {
        // buy the fund
        require(state == FundState.Issued, "Fund should be issuing!");
        require(msg.sender == fundHolder, "You are not the fund holder!");

        deTrustToken.transfer(fundManager, fundValue.mul(fundShares));
        state = FundState.Active;
    }

    function transfer(address _transferee) public {
        // sell the fund
        require(state == FundState.Active, "Fund should be active!");
        require(msg.sender == fundHolder, "You are not the fund holder!");

        fundHolder = _transferee;
    }

    function payYield() public {
        // pay interest to the fund holders
        require(state == FundState.Active, "Fund should be active!");
        require(msg.sender == fundManager, "Only fund manager can pay interest!");
        require(block.timestamp >= interestPaymentDate, "Interest payment date has not reached!");
    
        deTrustToken.transfer(fundHolder, fundValue.mul(fundShares).mul(yieldRate.sub(commisionRate)).div(100));
        interestPaymentDate = interestPaymentDate.add(interestInterval);
    }

    function updateYieldRate(uint256 _newYieldRate) public {
        // update the yield rate
        require(msg.sender == fundManager, "Only fund manager can update yield rate!");

        yieldRate = _newYieldRate;
    }

    function updateCommisionRate(uint256 _newCommisionRate) public {
        // update the commision rate
        require(msg.sender == fundManager, "Only fund manager can update commision rate!");

        commisionRate = _newCommisionRate;
    }

    function terminateFundContract() public {
        require(msg.sender == fundHolder, "Only fund holder can terminate the fund contract!");

        state = FundState.Terminated;
        selfdestruct(payable(address(this)));
    }
}