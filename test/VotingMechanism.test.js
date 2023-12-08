const { expect } = require("chai");
const { ethers } = require("hardhat");    
const web3 = require("web3");

describe("VotingMechanism", async () => {

    let ownerAddress, user1Address, user2Address, user3Address, user4Address, user5Address, user6Address, user7Address;
    let trustScoreAddress, deTrustTokenAddress, baseContractAddress, votingMechanismAddress, contractAddr;
    let trustScore, deTrustToken, baseContract, votingMechanism;
    let owner, user1, user2, user3, user4, user5, user6, user7, a1, a2, a3, a4, a5;
    
    before(async () => {

        [owner, user1, user2, user3, user4, user5, user6, user7, a1, a2, a3, a4, a5] = await ethers.getSigners();

        ownerAddress = await owner.getAddress();
        user1Address = await user1.getAddress();
        user2Address = await user2.getAddress();
        user3Address = await user3.getAddress();
        user4Address = await user4.getAddress();
        user5Address = await user5.getAddress();
        user6Address = await user6.getAddress();
        user7Address = await user7.getAddress();

        trustScore = await ethers.deployContract("TrustScore", [200]);
        trustScoreAddress = await trustScore.getAddress();

        deTrustToken = await ethers.deployContract("DeTrustToken", [1000000000000000]);
        deTrustTokenAddress = await deTrustToken.getAddress();

        baseContract = await ethers.deployContract("BaseContract", 
            [trustScoreAddress, deTrustTokenAddress]);
        baseContractAddress = await baseContract.getAddress();

        votingMechanism = await ethers.deployContract("VotingMechanism",
            [baseContractAddress, deTrustTokenAddress, trustScoreAddress]);
        votingMechanismAddress = await votingMechanism.getAddress();

        await trustScore.connect(owner).setTrustScore(user1Address, 450);
        await trustScore.connect(owner).setTrustScore(user2Address, 450);
        await trustScore.connect(owner).setTrustScore(user3Address, 450);   
        await trustScore.connect(owner).setTrustScore(user4Address, 450);
        await trustScore.connect(owner).setTrustScore(user5Address, 450);
        await trustScore.connect(owner).setTrustScore(user6Address, 450);
        await trustScore.connect(owner).setTrustScore(user7Address, 450);

        await deTrustToken.connect(owner).mintFor(user1Address, 1020);
        await deTrustToken.connect(owner).mintFor(user2Address, 1020);
        await deTrustToken.connect(owner).mintFor(user3Address, 600);
        await deTrustToken.connect(owner).mintFor(user4Address, 600);
        await deTrustToken.connect(owner).mintFor(user5Address, 600);
        await deTrustToken.connect(owner).mintFor(user6Address, 600);
        await deTrustToken.connect(owner).mintFor(user7Address, 600);
        await deTrustToken.connect(owner).mintFor(baseContractAddress, 500);
        await deTrustToken.connect(owner).setApproval(baseContractAddress);
        await deTrustToken.connect(owner).setApproval(votingMechanismAddress);

        await trustScore.connect(owner).approveAddress(baseContractAddress);
        await trustScore.connect(owner).approveAddress(votingMechanismAddress);

        await baseContract.connect(owner).setVotingAccess(votingMechanismAddress);

        await deTrustToken.connect(user1).approve(baseContractAddress, 20);
        await deTrustToken.connect(user2).approve(baseContractAddress, 20); 

        const commonInput =
            [baseContractAddress, [user1Address, user3Address], 
            [user2Address, user4Address], user2Address, user1Address,
            "common1", "type1", ["ob1", "ob2"], ["desc1", "desc2"], [10000000000, 30000000000], 2, 0];

        const CommonContract = await ethers.getContractFactory("CommonContract");
        const commonContract = await CommonContract.connect(user2).deploy(commonInput);
        contractAddr = await commonContract.getAddress();

        const creationTime = Math.floor(Date.now() / 1000);
        const string1 = web3.utils.padLeft(web3.utils.fromAscii("ad1"), 64);
        const string2 = web3.utils.padLeft(web3.utils.fromAscii("ad2"), 64);

        const validProperties1 = [
            1, 
            0, 
            creationTime, 
            1, 
            0, 
            [user1Address, string1, user2Address, string2, 2],
            0,
            8,
            0,
            0,
            false];

        const setProperties = await baseContract.setGeneralRepo(1, validProperties1);
        expect(setProperties).to.emit(baseContract, "PropertiesRecorded").withArgs(1);

    });

    it ("Should be able to vote a contract", async () => {
        const initTokenBalance3 = await deTrustToken.balanceOf(user3Address);
        const initTokenBalance4 = await deTrustToken.balanceOf(user4Address);
        const initTokenBalance5 = await deTrustToken.balanceOf(user5Address);
        const initTokenBalance6 = await deTrustToken.balanceOf(user6Address);
        const initTokenBalance7 = await deTrustToken.balanceOf(user7Address);
        const initTokenBalanceBase = await deTrustToken.balanceOf(baseContractAddress);
        expect(initTokenBalance3).to.equal(600);
        expect(initTokenBalance4).to.equal(600);
        expect(initTokenBalance5).to.equal(600);
        expect(initTokenBalance6).to.equal(600);
        expect(initTokenBalance7).to.equal(600);
        expect(initTokenBalanceBase).to.equal(540);

        const currentTime = Math.floor(Date.now() / 1000);

        const vote1 = await votingMechanism.connect(user3).verifyContract(1, 1, user3Address, currentTime);
        expect(vote1).to.emit(votingMechanism, "VerifiedContract").withArgs(1, user3Address, 1, currentTime);
        const vote2 = await votingMechanism.connect(user4).verifyContract(1, 1, user4Address, currentTime);
        expect(vote2).to.emit(votingMechanism, "VerifiedContract").withArgs(1, user4Address, 1, currentTime);
        const vote3 = await votingMechanism.connect(user5).verifyContract(1, 2, user5Address, currentTime);
        expect(vote3).to.emit(votingMechanism, "VerifiedContract").withArgs(1, user5Address, 2, currentTime);
        const vote4 = await votingMechanism.connect(user6).verifyContract(1, 1, user6Address, currentTime);
        expect(vote4).to.emit(votingMechanism, "VerifiedContract").withArgs(1, user6Address, 1, currentTime);
        const vote5 = await votingMechanism.connect(user7).verifyContract(1, 1, user7Address, currentTime);
        expect(vote5)
        .to.emit(votingMechanism, "VerifiedContract").withArgs(1, user7Address, 1, currentTime)
        .and.to.emit(votingMechanism, "PassedVerification").withArgs(1);

        const generalRepo = await baseContract.getGeneralRepo(1);
        expect(generalRepo[6]).to.equal(0);
        expect(generalRepo[8]).to.equal(4);
        expect(generalRepo[9]).to.equal(1);

        const finalTokenBalance3 = await deTrustToken.balanceOf(user3Address);
        const finalTokenBalance4 = await deTrustToken.balanceOf(user4Address);
        const finalTokenBalance5 = await deTrustToken.balanceOf(user5Address);
        const finalTokenBalance6 = await deTrustToken.balanceOf(user6Address);
        const finalTokenBalance7 = await deTrustToken.balanceOf(user7Address);
        const finalTokenBalanceBase = await deTrustToken.balanceOf(baseContractAddress);
        expect(finalTokenBalance3).to.equal(610);
        expect(finalTokenBalance4).to.equal(610);
        expect(finalTokenBalance5).to.equal(610);
        expect(finalTokenBalance6).to.equal(610);
        expect(finalTokenBalance7).to.equal(610);
        expect(finalTokenBalanceBase).to.equal(490);

    });

    it ("Should be able to resolve verification result", async () => {
        const initTokenBalance5 = await deTrustToken.balanceOf(user5Address);
        expect(initTokenBalance5).to.equal(610);

        const initTrustScore1 = await trustScore.getTrustScore(user1Address);
        const initTrustScore2 = await trustScore.getTrustScore(user2Address);
        const initTrustScore5 = await trustScore.getTrustScore(user5Address);
        expect(initTrustScore1).to.equal(450);
        expect(initTrustScore2).to.equal(450);
        expect(initTrustScore5).to.equal(450);

        const currentTime = Math.floor(Date.now() / 1000);

        const resolve = await votingMechanism.resolveVerification(1, currentTime);
        expect(resolve).to.emit(votingMechanism, "VerificationResolved").withArgs(1, 1, currentTime);

        const generalRepo = await baseContract.getGeneralRepo(1);
        expect(generalRepo[1]).to.equal(2);
        expect(generalRepo[6]).to.equal(1);

        const finalTokenBalance5 = await deTrustToken.balanceOf(user5Address);
        expect(finalTokenBalance5).to.equal(510);

        const finalTrustScore1 = await trustScore.getTrustScore(user1Address);
        const finalTrustScore2 = await trustScore.getTrustScore(user2Address);
        const finalTrustScore5 = await trustScore.getTrustScore(user5Address);
        expect(finalTrustScore1).to.equal(450);
        expect(finalTrustScore2).to.equal(450);
        expect(finalTrustScore5).to.equal(449);
    });
});