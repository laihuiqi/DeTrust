const { expect } = require("chai");
const { ethers } = require("hardhat");    
const web3 = require("web3");

describe("BaseContract", async () => {

    let ownerAddress, user1Address, user2Address, user3Address, user4Address, user5Address, user6Address;
    let trustScoreAddress, deTrustTokenAddress, baseContractAddress, votingMechanismAddress, contractAddr, commonContractAddress;
    let trustScore, deTrustToken, baseContract, votingMechanism;
    let owner, user1, user2, user3, user4, user5, user6, a1, a2, a3, a4, a5;

    let contractInput;
    
    before(async () => {

        [owner, user1, user2, user3, user4, user5, user6, a1, a2, a3, a4, a5] = await ethers.getSigners();

        ownerAddress = await owner.getAddress();
        user1Address = await user1.getAddress();
        user2Address = await user2.getAddress();
        user3Address = await user3.getAddress();
        user4Address = await user4.getAddress();
        user5Address = await user5.getAddress();
        user6Address = await user6.getAddress();

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

        contractAddr = await a1.getAddress();
        contractInput = [contractAddr, 0, 0, user1Address, user2Address, user1Address, user2Address];

        await trustScore.connect(owner).setTrustScore(user1Address, 450);
        await trustScore.connect(owner).setTrustScore(user2Address, 450);

        await deTrustToken.connect(owner).mintFor(user1Address, 1000);
        await deTrustToken.connect(owner).mintFor(user2Address, 1000);
        await deTrustToken.connect(owner).setApproval(baseContractAddress);
        await deTrustToken.connect(owner).setApproval(votingMechanismAddress);

        await deTrustToken.connect(user1).approve(baseContractAddress, 20);   
        await deTrustToken.connect(user2).approve(baseContractAddress, 20);
        await trustScore.connect(owner).approveAddress(baseContractAddress);
        await trustScore.connect(owner).approveAddress(votingMechanismAddress);

        await baseContract.connect(owner).setVotingAccess(votingMechanismAddress);

        console.log("Completed init account settings!");

        const creationTime = Date.now() - 36000;
        const string1 = web3.utils.padLeft(web3.utils.fromAscii("ad1"), 64);
        const string2 = web3.utils.padLeft(web3.utils.fromAscii("ad2"), 64);

        const validProperties1 = [
            6, 
            0, 
            creationTime, 
            0, 
            0, 
            [user1Address, string1, user2Address, string2, 1],
            0,
            8,
            0,
            0,
            false];

        const validProperties2 = [
            7, 
            2, 
            creationTime, 
            0, 
            0, 
            [user1Address, string1, user2Address, string2, 2],
            1,
            8,
            4,
            0,
            false];

        const setProperties = await baseContract.setGeneralRepo(6, validProperties1);
        expect(setProperties).to.emit(baseContract, "PropertiesRecorded").withArgs(6);
        console.log("Successfully set properties for default contract id 6");

        const setProperties2 = await baseContract.setGeneralRepo(7, validProperties2);
        expect(setProperties2).to.emit(baseContract, "PropertiesRecorded").withArgs(7);
        console.log("Successfully set properties for default contract id 7");
    });

    it("Should be able to record a new contract", async () => {
        const initTokenBalance1 = await deTrustToken.balanceOf(user1Address);
        const initTokenBalance2 = await deTrustToken.balanceOf(user2Address);
        const initTokenBalance3 = await deTrustToken.balanceOf(baseContractAddress);
        expect(initTokenBalance1).to.equal(1000);
        expect(initTokenBalance2).to.equal(1000);
        expect(initTokenBalance3).to.equal(0);
        console.log("\n\nSuccessfully checked init token balance for user 1, user 2 and base contract");

        const logContract = await baseContract.addToContractRepo(contractInput);
        expect(logContract).to.emit(baseContract, "ContractLogged").withArgs(contractAddr, 1);

        const finalTokenBalance1 = await deTrustToken.balanceOf(user1Address);
        const finalTokenBalance2 = await deTrustToken.balanceOf(user2Address);
        const finalTokenBalance3 = await deTrustToken.balanceOf(baseContractAddress);
        expect(finalTokenBalance1).to.equal(980);
        expect(finalTokenBalance2).to.equal(980);
        expect(finalTokenBalance3).to.equal(40);
        console.log("Successfully checked final token balance for user 1, user 2 and base contract");
        
        const generalRepo = await baseContract.getGeneralRepo(1);
        expect(generalRepo[0]).to.equal(1); // counter
        expect(generalRepo[1]).to.equal(0); // draft
        expect(generalRepo[3]).to.equal(0); // common type
        expect(generalRepo[4]).to.equal(0); // dispute type
        expect(generalRepo[6]).to.equal(0); // pending verification
        expect(generalRepo[7]).to.equal(8); // verifier amount
        expect(generalRepo[8]).to.equal(0); 
        expect(generalRepo[9]).to.equal(0);
        expect(generalRepo[10]).to.equal(false);
        
        const addressMapping = await baseContract.getAddressRepo(1);
        expect(addressMapping).to.equal(contractAddr);

        const idMapping = await baseContract.getIdRepo(contractAddr);
        expect(idMapping).to.equal(1);

        const walletAddress1 = await baseContract.getWalletAddress(user1Address);
        expect(walletAddress1).to.equal(user1Address);

        const walletAddress2 = await baseContract.getWalletAddress(user2Address);
        expect(walletAddress2).to.equal(user2Address);
        console.log("Successfully recorded contract 1");
    });

    it("Should be able to proceed verified contract", async () => {
        const creationTime = Date.now() - 36000;
        const string1 = web3.utils.padLeft(web3.utils.fromAscii("ad1"), 64);
        const string2 = web3.utils.padLeft(web3.utils.fromAscii("ad2"), 64);
        const validProperties = [
            2, 
            1, 
            creationTime, 
            0, 
            0, 
            [user1Address, string1, user2Address, string2, 2],
            1,
            8,
            5,
            1,
            false];

        const setProperties = await baseContract.setGeneralRepo(2, validProperties);
        expect(setProperties).to.emit(baseContract, "PropertiesRecorded").withArgs(2);
        console.log("\n\nSuccessfully set properties for contract 2");

        const checkGeneralRepo = await baseContract.getGeneralRepo(2);
        expect(checkGeneralRepo[0]).to.equal(2); // counter
        expect(checkGeneralRepo[1]).to.equal(1); 
        expect(checkGeneralRepo[2]).to.equal(creationTime);
        expect(checkGeneralRepo[3]).to.equal(0); 
        expect(checkGeneralRepo[4]).to.equal(0);
        expect(checkGeneralRepo[5][0]).to.equal(user1Address);
        expect(checkGeneralRepo[5][1]).to.equal(string1);
        expect(checkGeneralRepo[5][2]).to.equal(user2Address);
        expect(checkGeneralRepo[5][3]).to.equal(string2);
        expect(checkGeneralRepo[5][4]).to.equal(2);
        expect(checkGeneralRepo[6]).to.equal(1);
        expect(checkGeneralRepo[7]).to.equal(8);
        expect(checkGeneralRepo[8]).to.equal(5);
        expect(checkGeneralRepo[9]).to.equal(1);
        expect(checkGeneralRepo[10]).to.equal(false);
        console.log("Successfully checked init properties for contract 2");

        const proceedContract = await baseContract.connect(user1).proceedContract(2);
        expect(proceedContract).to.emit(baseContract, "ContractProceeded").withArgs(2);
        console.log("Successfully proceeded contract 2 by user 1");

        const generalRepo = await baseContract.getGeneralRepo(2);
        expect(generalRepo[0]).to.equal(2); // counter
        expect(generalRepo[1]).to.equal(2); // In progress
        console.log("Successfully checked updated properties for contract 2");
    });

    it("Should be able to complete contract", async () => {
        const creationTime = Date.now() - 36000;
        const string1 = web3.utils.padLeft(web3.utils.fromAscii("ad1"), 64);
        const string2 = web3.utils.padLeft(web3.utils.fromAscii("ad2"), 64);
        const validProperties = [
            3, 
            2, 
            creationTime, 
            0, 
            0, 
            [user1Address, string1, user2Address, string2, 2],
            1,
            8,
            4,
            0,
            false];

        const setProperties = await baseContract.setGeneralRepo(3, validProperties);
        expect(setProperties).to.emit(baseContract, "PropertiesRecorded").withArgs(3);
        console.log("\n\nSuccessfully set properties for contract 3");

        const initTrustScore1 = await trustScore.getTrustScore(user1Address);
        const initTrustScore2 = await trustScore.getTrustScore(user2Address);
        expect(initTrustScore1).to.equal(450);
        expect(initTrustScore2).to.equal(450);
        console.log("Successfully checked init trust score for user 1 and user 2");

        const completeContract = await baseContract.connect(user1).completeContract(3);
        expect(completeContract).to.emit(baseContract, "ContractPendingComplete").withArgs(3);
        console.log("Contract 3 is pending complete by user 1");

        const generalRepo = await baseContract.getGeneralRepo(3);
        expect(generalRepo[10]).to.equal(true); 
        console.log("Successfully checked updated properties for contract 3 on pending complete");

        const completeContract2 = await baseContract.connect(user2).completeContract(3);
        expect(completeContract2).to.emit(baseContract, "ContractCompleted").withArgs(3);
        console.log("Contract 3 is completed by user 2");

        const generalRepo2 = await baseContract.getGeneralRepo(3);
        expect(generalRepo2[1]).to.equal(4);
        expect(generalRepo2[10]).to.equal(true);
        console.log("Successfully checked updated properties for contract 3 on completed");

        const finalTrustScore1 = await trustScore.getTrustScore(user1Address);
        const finalTrustScore2 = await trustScore.getTrustScore(user2Address);
        expect(finalTrustScore1).to.equal(451);
        expect(finalTrustScore2).to.equal(451);
        console.log("Successfully checked final trust score for user 1 and user 2");
    });

    it ("Should be able to void contract", async () => {
        const creationTime = Date.now() - 36000;
        const string1 = web3.utils.padLeft(web3.utils.fromAscii("ad1"), 64);
        const string2 = web3.utils.padLeft(web3.utils.fromAscii("ad2"), 64);
        const validProperties = [
            4, 
            2, 
            creationTime, 
            0, 
            0, 
            [user1Address, string1, user2Address, string2, 2],
            1,
            8,
            4,
            0,
            false];

        const setProperties = await baseContract.setGeneralRepo(4, validProperties);
        expect(setProperties).to.emit(baseContract, "PropertiesRecorded").withArgs(4);
        console.log("\n\nSuccessfully set properties for contract 4");

        const voidContract = await baseContract.connect(user1).voidContract(4);
        expect(voidContract).to.emit(baseContract, "ContractVoided").withArgs(4);
        console.log("Contract 4 is voided by user 1");

        const generalRepo = await baseContract.getGeneralRepo(4);
        expect(generalRepo[1]).to.equal(5);
        console.log("Successfully checked updated properties for contract 4 on voided");
    });

    it ("Should be able to record dispute on contract", async () => {
        const creationTime = Date.now() - 36000;
        const string1 = web3.utils.padLeft(web3.utils.fromAscii("ad1"), 64);
        const string2 = web3.utils.padLeft(web3.utils.fromAscii("ad2"), 64);
        const validProperties = [
            5, 
            2, 
            creationTime, 
            0, 
            0, 
            [user1Address, string1, user2Address, string2, 2],
            1,
            8,
            4,
            0,
            false];

        const setProperties = await baseContract.setGeneralRepo(5, validProperties);
        expect(setProperties).to.emit(baseContract, "PropertiesRecorded").withArgs(5);
        console.log("\n\nSuccessfully set properties for contract 5");

        const disputeContractAddress = await a2.getAddress();
        console.log("Deployed DeTrustToken contract: ", deTrustTokenAddress);
        const disputeContract = await baseContract.connect(user1)
            .disputeContract(5, disputeContractAddress, 1);
        expect(disputeContract).to.emit(baseContract, "ContractDisputeRecorded").withArgs(5);
        console.log("Contract 5 is disputed by user 1");

        const generalRepo = await baseContract.getGeneralRepo(5);
        expect(generalRepo[1]).to.equal(3);
        expect(generalRepo[4]).to.equal(1);

        const disputeRepo = await baseContract.getDisputeContract(5);
        expect(disputeRepo).to.equal(disputeContractAddress);
        console.log("Successfully checked updated properties for contract 5 on disputed");
    });

    it ("Should be able to check if contract is inprogress", async () => {
        const checkInProgress = await baseContract.isContractReady(6);
        expect(checkInProgress).to.equal(false);
        console.log("\n\nSuccessfully checked contract 6 is not in progress");

        const checkInProgress2 = await baseContract.isContractReady(7);
        expect(checkInProgress2).to.equal(true);
        console.log("Successfully checked contract 7 is in progress");
    });

    it ("Should be able to check if contract is signed", async () => {
        await expect(baseContract.connect(user1)
            .isSigned(6)).to.be.revertedWith("Contract is not signed by both parties!");
        console.log("\n\nSuccessfully checked contract 6 is not signed");

        const checkSigned2 = await baseContract.isSigned(7);
        expect(checkSigned2).to.equal(true);
        console.log("Successfully checked contract 7 is signed");
    });
});