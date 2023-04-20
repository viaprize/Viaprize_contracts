import { expect } from "chai";
import { ethers } from "hardhat";
import { YourContract, SubmissionAVLTree } from "../typechain-types";
import { Contract, BigNumber, Signer } from "ethers";

describe("YourContract", function () {
  let YourContract, yourContract: Contract;
  let SubmissionAVLTree, submissionAVLTree: Contract;
  let owner, addr1, addr2, addr3, addr4;

  beforeEach(async function () {
    SubmissionAVLTree = await ethers.getContractFactory("SubmissionAVLTree");
    YourContract = await ethers.getContractFactory("YourContract");
    [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    submissionAVLTree = await SubmissionAVLTree.deploy();
    yourContract = await YourContract.deploy(submissionAVLTree.address);
    await yourContract.deployed();
  });

  it("listens for RefundInfo event", async () => {
    // Replace the following line with the actual function call that triggers the RefundInfo event
    const tx = await yourContract.claimRefund(addr1.address);

    const event = tx.logs?.find((log) => log.event === "RefundInfo");
    if (event) {
      console.log("Refund amount:", event.args.refundAmount.toString());
      console.log("Total refund amount:", event.args.totalRefundAmount.toString());
    } else {
      console.error("RefundInfo event not found");
    }
  });

  

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await yourContract.admins(owner.address)).to.equal(true);
    });
  });

  describe("Functions", function () {

    it("Should add funds and update total_funds", async function () {
      await yourContract.connect(owner).start_submission_period(2);
      await yourContract.connect(addr1).addFunds({ value: ethers.utils.parseEther("1") });
      expect(await yourContract.funders(addr1.address)).to.equal(ethers.utils.parseEther("1"));
      expect(await yourContract.total_funds()).to.equal(ethers.utils.parseEther("1"));
    });

    it("Should allow admin to start and end submission period", async function () {
      await yourContract.start_submission_period(2);

      expect(await yourContract.get_submission_time()).to.not.equal(0);

      await yourContract.end_submission_period();

      expect(await yourContract.get_submission_time()).to.equal(0);

    });

    it("Should allow admin to start voting period", async function () {
      await yourContract.start_voting_period(2);
      expect(await yourContract.get_voting_time()).to.not.equal(0);
    });

    it("Should allow users to add submissions", async function () {
      await yourContract.start_submission_period(2);
      const submissionText = "Test submission";
      const threshold = 10;
      const submissionHash = await yourContract.addSubmission(addr1.address, submissionText, threshold);


      const submissions = await yourContract.getAllSubmissions();

      expect (submissions.submissionHash).to.equal(submissionHash.submissionHash);
    });

    it("Should allow users to vote on submissions and update their votes", async function () {
      await yourContract.start_submission_period(2);
      const submissionText = "Test submission";
      const submissionText2 = "Test submission 2";
      const threshold = ethers.utils.parseEther("0.5");
      const submission1 = await yourContract.addSubmission(addr1.address, submissionText, threshold);
      const submission2 = await yourContract.addSubmission(addr2.address, submissionText2, threshold);

      const allSubmissions = await yourContract.getAllSubmissions();

      await yourContract.end_submission_period();

      await yourContract.start_voting_period(2);
      await yourContract.connect(addr1).addFunds({ value: ethers.utils.parseEther("1") });

      await yourContract.connect(addr1).vote(allSubmissions[0].submissionHash, ethers.utils.parseEther("0.5"));

      const allSubmissionsCheck = await yourContract.getAllSubmissions();


      //parse allSubmissionsCheck[0].votes from Bignumber hex to number
      expect(allSubmissionsCheck[0].votes).to.equal(ethers.utils.parseEther("0.5"));

      console.log("StateCheck", Number(allSubmissionsCheck[0].votes));

      await yourContract.connect(addr1).change_vote(allSubmissionsCheck[0].submissionHash, allSubmissionsCheck[1].submissionHash, ethers.utils.parseEther("0.5"));

      const SubmissionsStateCheck = await yourContract.getAllSubmissions();
      const updatedSubmission = SubmissionsStateCheck[0];
      const newSubmission = SubmissionsStateCheck[1];
      expect(updatedSubmission.votes).to.equal(ethers.utils.parseEther("0"));
      expect(newSubmission.votes).to.equal(ethers.utils.parseEther("0.5"));
    });

    it("Should distribute rewards to funded submissions and platform", async function () {
      await yourContract.start_submission_period(2);
      const submissionText = "Test submission";
      const threshold = ethers.utils.parseEther("0.5");
      const submissionHash = await yourContract.addSubmission(addr2.address, submissionText, threshold);
      const starting_balance = await addr2.getBalance();
      const platform_address = "0xcd258fCe467DDAbA643f813141c3560FF6c12518";
      const balance_address = await ethers.provider.getBalance(platform_address);



      await yourContract.connect(addr1).addFunds({ value: ethers.utils.parseEther("0.5") });

      await yourContract.end_submission_period();

      await yourContract.start_voting_period(2);
      const allSubmissions = await yourContract.getAllSubmissions();

      await yourContract.connect(addr1).vote(allSubmissions[0].submissionHash, ethers.utils.parseEther("0.5"));
      const submissionState = await yourContract.getAllSubmissions();

      expect(submissionState[0].funded).to.equal(true);
      expect(submissionState[0].votes).to.equal(ethers.utils.parseEther("0.5"));
      console.log('submissionvotes', Number(submissionState[0].votes));
      await yourContract.end_voting_period();

      //make sure that the address balance of the submission owner has increased by the amount of 95% of the total votes
      const amount = ethers.utils.parseEther("0.475");

      const added = starting_balance + amount;

      const balancer = await addr2.getBalance();
      //expect balancer to > starting_balance
      console.log('failed');
      expect(balancer.gt(starting_balance)).to.be.true;
      console.log('passed');

      const reward = ethers.utils.parseEther("0.025");
      const adding = balance_address.add(reward);
      const platform_balance = await ethers.provider.getBalance(platform_address);

      //make sure that the platform address has increased by the amount of 5% of the total votes
      expect (platform_balance.gt(balance_address)).to.be.true;

    });

    it("Should allow users to claim refunds for unfunded submissions", async function () {
      await yourContract.start_submission_period(2);
      const submissionText = "Test submission";
      const threshold = ethers.utils.parseEther("1");
      const submissionHash = await yourContract.addSubmission(addr2.address, submissionText, threshold);
      const getSubmissions = await yourContract.getAllSubmissions();
      const initial_balance = await addr1.getBalance();
      console.log("initial", Number(initial_balance));

      await yourContract.end_submission_period();

      await yourContract.connect(addr1).addFunds({ value: ethers.utils.parseEther("1") });
      await yourContract.start_voting_period(2);
      const tx = await yourContract.connect(addr1).vote(getSubmissions[0].submissionHash, ethers.utils.parseEther("0.9"));

      console.log("Submission hash:", getSubmissions[0].submissionHash);
      console.log("Submission votes:", Number(getSubmissions[0].votes));

      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed;
      const gasPrice = tx.gasPrice;
      const transactionCost = gasUsed.mul(gasPrice);

      console.log("Gas price:", Number(gasPrice));
      console.log("Gas used:", Number(gasUsed));
      console.log("Transaction cost:", Number(transactionCost));

    
      await yourContract.end_voting_period();
    
      await yourContract.connect(owner).claimRefund(addr1.address);
      
      const balance_state = await addr1.getBalance();
    
      const expected_balance = ((initial_balance.sub(transactionCost).mul(95)).div(100));

      console.log("Initial balance:", Number(initial_balance));
      console.log("Balance after claiming refund:", Number(balance_state));
      console.log("Expected balance:", Number(expected_balance));

      expect(balance_state.gte(expected_balance)).to.be.true;
    });

    it("Should withdraw platform funds after distributing rewards", async function () {
      await yourContract.start_submission_period(2);
      const submissionText = "Test submission";
      const threshold = ethers.utils.parseEther("0.5");
      const submissionHash = await yourContract.addSubmission(addr1.address, submissionText, threshold);

      const allSubmissions = await yourContract.getAllSubmissions();

      await yourContract.connect(addr1).addFunds({ value: ethers.utils.parseEther("0.5") });
      await yourContract.end_submission_period();
      await yourContract.start_voting_period(2);
      await yourContract.connect(addr1).vote(allSubmissions[0].submissionHash, ethers.utils.parseEther("0.5"));



      const initialPlatformBalance = await ethers.provider.getBalance(yourContract.PLATFORM_ADDRESS());
      await yourContract.end_voting_period();

      const newPlatformBalance = await ethers.provider.getBalance(yourContract.PLATFORM_ADDRESS());

      expect(newPlatformBalance.gt(initialPlatformBalance)).to.equal(true);
    });

    it("Should not allow a user to vote with more funds than they have", async function () {
      await yourContract.start_submission_period(2);
      const submissionText = "Test submission";
      const threshold = ethers.utils.parseEther("0.5");
      const submissionHash = await yourContract.addSubmission(addr1.address, submissionText, threshold);

      const allSubmissions = await yourContract.getAllSubmissions();

      await yourContract.connect(addr1).addFunds({ value: ethers.utils.parseEther("0.5") });

      await yourContract.end_submission_period();
      await yourContract.start_voting_period(2);

      // addr1 votes for the submission
      await yourContract.connect(addr1).vote(allSubmissions[0].submissionHash, ethers.utils.parseEther("0.5"));
  
      // addr1 tries to vote again, which should revert
      await expect(yourContract.connect(addr1).vote(allSubmissions[0].submissionHash, ethers.utils.parseEther("0.5"))).to.be.revertedWith("You do not have enough funds to vote this amount");
    });
  
    it("Should not allow a user to change someone else's votes", async function () {
      await yourContract.start_submission_period(2);
      const submissionText = "Test submission";
      const threshold = ethers.utils.parseEther("0.5");
      const submissionHash = await yourContract.addSubmission(addr1.address, submissionText, threshold);
      const submissionHash2 = await yourContract.addSubmission(addr2.address, submissionText, threshold);

      await yourContract.connect(addr1).addFunds({ value: ethers.utils.parseEther("0.5") });

      await yourContract.end_submission_period();
      await yourContract.start_voting_period(2);

      const allSubmissions = await yourContract.getAllSubmissions();

      // addr1 votes for the submission
      await yourContract.connect(addr1).vote(allSubmissions[0].submissionHash, ethers.utils.parseEther("0.5"));

      const allSubmissionsState = await yourContract.getAllSubmissions();
  
      // addr2 tries to remove addr1's votes, which should revert
      await expect(yourContract.connect(addr2).change_vote(allSubmissionsState[0].submissionHash, allSubmissionsState[1].submissionHash, ethers.utils.parseEther("0.5"))).to.be.revertedWith("You do not have enough votes on the previous submission from this address");
    });



  });
});
