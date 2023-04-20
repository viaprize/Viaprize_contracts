// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubmissionAVLTree.sol";

contract YourContract {
    // ... (existing variables and structs)
    uint256 submission_time; //this will be the time that the submission period ends
    uint256 voting_time; //this will be the time that the voting period ends

    mapping (address => uint256) public funders; //this will be a mapping of the addresses of the funders to the amount of eth they have contributed

    mapping (address => mapping(uint256 => uint256)) public votes; //this will be a mapping of the addresses of the funders to the amount of votes they have

    address public constant PLATFORM_ADDRESS = 0xcd258fCe467DDAbA643f813141c3560FF6c12518; //this will be the address of the platform

    address[] public funderAddresses; //this will be an array of the addresses of the funders making it easier to iterate through them

    bytes32[] public thresholdCrossedSubmissions;

    //create a struct for the submissions
    struct Submission {
        address submitter;
        string submission;
        uint256 votes;
        uint256 threshold;
        bool funded;
        }

    Submission[] public submissions; //this will be an array of the submissions

    mapping (address => bool) public admins; //this will be a mapping of the addresses of the admins to a boolean value of true or false

    uint256 public total_votes; //this will be the total number of votes

    uint256 public total_funds; //this will be the total amount of funds raised

    uint256 public total_rewards; //this will be the total amount of rewards available

    SubmissionAVLTree private submissionTree;

        // Add a new mapping to store each funder's votes on each submission
    mapping(address => mapping(bytes32 => uint256)) public funderVotes;


    constructor() {
        //add as many admins as you need to -- replace msg.sender with the address of the admin(s) for now this means the deployer will be the sole admin
        admins[msg.sender] = true;
        admins[0xcd258fCe467DDAbA643f813141c3560FF6c12518] = true;
        // Initialize the submissionTree
        submissionTree = new SubmissionAVLTree();
    }

        // ... (existing functions)
        //create a function to start the submission period
    function start_submission_period(uint256 _submission_time) public {
        require(admins[msg.sender] == true, "You are not an admin");
        submission_time = block.timestamp + _submission_time * 1 days;
        //submission time will be in days
    }

    //end the submission period
    function end_submission_period() public {
        require(admins[msg.sender] == true, "You are not an admin");
        submission_time = 0;
    }

    function start_voting_period(uint256 _voting_time) public {
        require(admins[msg.sender] == true, "You are not an admin");
        require (block.timestamp > submission_time, "Submission period has not ended");
        voting_time = block.timestamp + _voting_time * 1 days;
        //voting time also in days
    }

    function end_voting_period() public {
        require(admins[msg.sender] == true, "You are not an admin");
        voting_time = 0;
    }

function updateThresholdStatus(bytes32 _submissionHash) internal {
    SubmissionAVLTree.SubmissionInfo memory submission = submissionTree.getSubmission(_submissionHash);
    if (!submission.thresholdCrossed && submission.votes >= submission.fundingThreshold) {
        submissionTree.setThresholdCrossed(_submissionHash, true);
        thresholdCrossedSubmissions.push(_submissionHash);
    }
}


    function addSubmission(address submitter, string memory submissionText, uint256 threshold) public {
    require(block.timestamp < submission_time, "Submission period has ended");
    bytes32 submissionHash = keccak256(abi.encodePacked(submitter, submissionText));
    submissionTree.insert(submissionHash, submitter, submissionText, threshold);
    }

    //create a function to allow funders to vote for a submission
    // Update the vote function
    function vote(bytes32 _submissionHash, uint256 amount) public {
        require(block.timestamp < voting_time, "Voting period has ended");
        require(amount <= funders[msg.sender], "You do not have enough funds to vote this amount");

        submissionTree.addVotes(_submissionHash, amount);
        funderVotes[msg.sender][_submissionHash] += amount;

        funders[msg.sender] -= amount; // Update funder's balance

        SubmissionAVLTree.SubmissionInfo memory submission = submissionTree.getSubmissionInfo(_submissionHash);
        if (submission.votes >= submission.threshold) {
        submissionTree.setFunded(_submissionHash, true);
    }
    }

    // Update the change_vote function
    function change_vote(bytes32 _previous_submissionHash, bytes32 _new_submissionHash, uint256 amount) public {
        require(block.timestamp < voting_time, "Voting period has ended");
        require(funderVotes[msg.sender][_previous_submissionHash] >= amount, "You do not have enough votes on the previous submission");

        submissionTree.subVotes(_previous_submissionHash, amount);
        submissionTree.addVotes(_new_submissionHash, amount);

        funderVotes[msg.sender][_previous_submissionHash] -= amount;
        funderVotes[msg.sender][_new_submissionHash] += amount;

            SubmissionAVLTree.SubmissionInfo memory previousSubmission = submissionTree.getSubmissionInfo(_previous_submissionHash);
        if (previousSubmission.votes < previousSubmission.threshold) {
        submissionTree.setFunded(_previous_submissionHash, false);
        }

        SubmissionAVLTree.SubmissionInfo memory newSubmission = submissionTree.getSubmissionInfo(_new_submissionHash);
        if (newSubmission.votes >= newSubmission.threshold) {
        submissionTree.setFunded(_new_submissionHash, true);
        }
        }


    // ... (existing functions)

    function getAllSubmissions() public view returns (SubmissionAVLTree.SubmissionInfo[] memory) {
        return submissionTree.inOrderTraversal();
    }

    function addFunds() public payable {
        require(block.timestamp < submission_time, "Submission period has ended");
        require(msg.value > 0, "You must send some funds");
            funders[msg.sender] += msg.value;
            total_funds += msg.value;
            funderAddresses.push(msg.sender);
            total_rewards += (msg.value * 95) / 100; // 95% of the funds will be used
    }

    receive () external payable {
    addFunds();
    }


    //create function to allow admins to withdraw funds to the submission winners and the platform but do not iterate through an unknown length array
    function use_unused_votes(uint _submissionIndex) public {
    require(admins[msg.sender] == true, "You are not an admin");
    require(block.timestamp < voting_time, "Voting period has ended");

    SubmissionAVLTree.SubmissionInfo memory submission = submissionTree.getByIndex(_submissionIndex);
    require(submission.exists, "Invalid submission");

    uint256 unused_admin_votes = total_funds - total_votes;
    submissionTree.addVotes(submission.hash, unused_admin_votes);
    total_votes += unused_admin_votes;
}

    // Add the withdraw function
    function withdraw(bytes32 _submissionHash) public {
    require(admins[msg.sender] == true, "You are not an admin");
    require(block.timestamp > voting_time, "Voting period has not ended");
    require(total_rewards > 0, "There are no rewards to withdraw");

    SubmissionAVLTree.SubmissionInfo memory submission = submissionTree.getSubmission(_submissionHash);
    require(submission.exists, "Invalid submission");
    require(submission.thresholdCrossed, "Submission has not crossed the threshold");
    uint256 totalRewards = total_rewards;
    total_rewards = 0;

    uint256 reward = (totalRewards * submission.votes) / total_votes;
    payable(submission.submitter).transfer(reward);





}


    //create a function to allow admins to withdraw funds to the submission winners and the platform but do not iterate through an unknown length array

    //create function for admins to withdraw funds to the platform
    function withdraw_platform_funds() public {
        require(admins[msg.sender] == true, "You are not an admin");
        require(block.timestamp > voting_time, "Voting period has not ended");
        require(total_rewards != 0, "There are no rewards to withdraw");

        uint256 platform_reward = (total_rewards * 5) / 100;
        payable(PLATFORM_ADDRESS).transfer(platform_reward);
        total_rewards -= platform_reward;
    }


    
}
