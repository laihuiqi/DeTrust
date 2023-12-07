const { expect } = require("chai");
const { ethers } = require("hardhat");    
const web3 = require("web3");

describe("CommonContract", async () => {

    let ownerAddress, user1Address, user2Address, user3Address, user4Address;
    let baseContractAddress, commonContractAddress, trustScoreAddress, deTrustTokenAddress, votingMechanismAddress;
    let baseContract, commonContract, trustScore, deTrustToken, votingMechanism;
    let owner, user1, user2, user3, user4, a1, a2, a3, a4, a5;

    let contractInput;
    
    before(async () => {

        [owner, user1, user2, user3, user4, a1, a2, a3, a4, a5] = await ethers.getSigners();

        ownerAddress = await owner.getAddress();
        user1Address = await user1.getAddress();
        user2Address = await user2.getAddress();
        user3Address = await user3.getAddress();
        user4Address = await user4.getAddress();

        console.log("Initiated hardhat network accounts!");

        trustScore = await ethers.deployContract("TrustScore", [200]);
        trustScoreAddress = await trustScore.getAddress();
        console.log("Deployed TrustScore contract: ", trustScoreAddress);

        deTrustToken = await ethers.deployContract("DeTrustToken", [1000000000000000]);
        deTrustTokenAddress = await deTrustToken.getAddress();
        console.log("Deployed DeTrustToken contract: ", deTrustTokenAddress);

        baseContract = await ethers.deployContract("BaseContract", 
            [trustScoreAddress, deTrustTokenAddress]);
        baseContractAddress = await baseContract.getAddress();
        console.log("Deployed BaseContract contract: ", baseContractAddress);

        votingMechanism = await ethers.deployContract("VotingMechanism",
            [baseContractAddress, deTrustTokenAddress, trustScoreAddress]);
        votingMechanismAddress = await votingMechanism.getAddress();
        console.log("Deployed VotingMechanism contract: ", votingMechanismAddress);

        console.log("Completed deployment of backbone contracts!");

        await deTrustToken.connect(owner).setApproval(baseContractAddress);
        await deTrustToken.connect(owner).setApproval(votingMechanismAddress);
        await trustScore.connect(owner).approveAddress(baseContractAddress);
        await trustScore.connect(owner).approveAddress(votingMechanismAddress);
        await baseContract.connect(owner).setVotingAccess(votingMechanismAddress);

        await deTrustToken.connect(owner).mintFor(user1Address, 1000);
        await deTrustToken.connect(owner).mintFor(user2Address, 1000);
        await trustScore.connect(owner).setTrustScore(user1Address, 450);
        await trustScore.connect(owner).setTrustScore(user2Address, 450);

        await deTrustToken.connect(user1).approve(baseContractAddress, 20);
        await deTrustToken.connect(user2).approve(baseContractAddress, 20);  
        
        console.log("Completed init account settings!");

        const commonInput =
            [baseContractAddress, [user1Address, user3Address], 
            [user2Address, user4Address], user2Address, user1Address,
            "common1", "type1", ["ob1", "ob2"], ["desc1", "desc2"], [10000000000, 30000000000], 2, 0];

        const CommonContract = await ethers.getContractFactory("CommonContract");
        commonContract = await CommonContract.connect(user2).deploy(commonInput);
        commonContractAddress = await commonContract.getAddress();
        
        console.log("Deployed commonContract contract: ", commonContractAddress);

        const finalTokenBalance1 = await deTrustToken.balanceOf(user1Address);
        const finalTokenBalance2 = await deTrustToken.balanceOf(user2Address);
        expect(finalTokenBalance1).to.equal(980);
        expect(finalTokenBalance2).to.equal(980);

        const creationTime = Math.floor((Date.now() - 600 * 1000) / 1000);
        const string1 = web3.utils.padLeft(web3.utils.fromAscii("ad1"), 64);
        const string2 = web3.utils.padLeft(web3.utils.fromAscii("ad2"), 64);

        const changedProperties = [
            1, 
            2, 
            creationTime, 
            0,
            0, 
            [user1Address, string1, user2Address, string2, 2],
            1,
            8,
            4,
            2,
            false];

        const changeProperties = await baseContract.connect(owner).setGeneralRepo(1, changedProperties);
        expect(changeProperties).to.emit(baseContract, "PropertiesRecorded").withArgs(1);
        console.log("Completed setting up general repo for testing!");

    });

    it ("Should be able to resolve obligations", async () => {
        const initBalance = await ethers.provider.getBalance(commonContractAddress);

        const initContractState = await commonContract.checkContractState();
        expect(initContractState[0]).to.equal(false);
        expect(initContractState[1]).to.equal(false);

        const obligation1 = await commonContract.connect(user1).resolveObligation(0, { value: 10000000000 });
        expect(obligation1).to.emit(commonContract, "ObligationDone").withArgs(0);
        const balance1 = await ethers.provider.getBalance(commonContractAddress);

        const checkObligation1 = await commonContract.checkObligationState(0);
        expect(checkObligation1[0]).to.equal(true);
        expect(checkObligation1[1]).to.equal(false);

        const contractState1 = await commonContract.checkContractState();
        expect(contractState1[0]).to.equal(false);
        expect(contractState1[1]).to.equal(false);
        console.log("\n\nCompleted resolving obligation0!");

        const obligation2 = await commonContract.connect(user3).resolveObligation(1, { value: 30000000000 });
        expect(obligation2).to.emit(commonContract, "ObligationDone").withArgs(1);
        const balance2 = await ethers.provider.getBalance(commonContractAddress);
        

        const checkObligation2 = await commonContract.checkObligationState(1);
        expect(checkObligation2[0]).to.equal(true);
        expect(checkObligation2[1]).to.equal(false);

        const contractState2 = await commonContract.checkContractState();
        expect(contractState2[0]).to.equal(true);
        expect(contractState2[1]).to.equal(false);
        console.log("Completed resolving obligation1!");

        expect(balance1 - initBalance).to.equal(10000000000);
        expect(balance2 - balance1).to.equal(30000000000);
        console.log("Checked balances of payers!");   

        console.log("Completed resolving obligations!");
    });

    it ("Should be able to verify obligations", async () => {
        const obligation1 = await commonContract.connect(user4).verifyObligationDone(0);
        expect(obligation1).to.emit(commonContract, "ObligationVerified").withArgs(0);

        const checkObligation1 = await commonContract.checkObligationState(0);
        expect(checkObligation1[0]).to.equal(true);

        const contractState = await commonContract.checkContractState();
        expect(contractState[0]).to.equal(true);
        expect(contractState[1]).to.equal(false);
        console.log("\n\nCompleted verifying obligation 0!");

        const obligation2 = await commonContract.connect(user2).verifyObligationDone(1);
        expect(obligation2).to.emit(commonContract, "ObligationVerified").withArgs(1);

        const checkObligation2 = await commonContract.checkObligationState(1);
        expect(checkObligation2[0]).to.equal(true);
        console.log("Completed verifying obligation 1!");

        const finalContractState = await commonContract.checkContractState();
        expect(finalContractState[0]).to.equal(true);
        expect(finalContractState[1]).to.equal(true);
        console.log("Completed verifying obligations!");
    });

    it ("Should be able to withdraw funds", async () => {
        const initialWealth = await ethers.provider.getBalance(user2Address);

        const withdraw = await commonContract.connect(user2).initiatorWithdraw();
        expect(withdraw).to.emit(commonContract, "InitiatorWithdrawn").withArgs(40000000000);
        const w = await withdraw.wait();
        const gases = BigInt(w.gasUsed) * BigInt(w.gasPrice);
        console.log("\n\nCompleted initiator withdrawing funds!");

        const finalWealth = await ethers.provider.getBalance(user2Address);
        expect(finalWealth + gases - initialWealth).to.equal(40000000000);
        console.log("Completed withdrawing funds!");
    });

    it ("Should be able to complete contract", async () => {
        const complete = await commonContract.connect(user1).endContract();
        expect(complete)
        .to.emit(commonContract, "ContractEnded").withArgs(commonContractAddress, 1, user1Address)
        .and.to.emit(baseContract, "ContractPendingComplete").withArgs(1);
        console.log("\n\nComplete contract by user1!");

        const confirmComplete = await baseContract.connect(user2).completeContract(1);
        expect(confirmComplete).to.emit(baseContract, "ContractCompleted").withArgs(1);
        console.log("Complete contract by user2!");

        const finalTrustScore1 = await trustScore.getTrustScore(user1Address);
        const finalTrustScore2 = await trustScore.getTrustScore(user2Address);
        expect(finalTrustScore1).to.equal(451);
        expect(finalTrustScore2).to.equal(451);
        console.log("Completed updating trust score!");

        const generalRepo = await baseContract.getGeneralRepo(1);
        expect(generalRepo[0]).to.equal(1);
        expect(generalRepo[1]).to.equal(4);
        expect(generalRepo[10]).to.equal(true);

        console.log("Completed contract completion!");
    });
});