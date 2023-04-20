// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubmissionAVLTree.sol";


contract YourContract {

    uint256 submission_time; //this will be the time that the submission period ends
    uint256 voting_time; //this will be the time that the voting period ends

    mapping (address => uint256) public funders; //this will be a mapping of the addresses of the funders to the amount of eth they have contributed

    mapping (address => mapping(uint256 => uint256)) public votes; //this will be a mapping of the addresses of the funders to the amount of votes they have

    address public constant PLATFORM_ADDRESS = 0xcd258fCe467DDAbA643f813141c3560FF6c12518; //this will be the address of the platform

    address[] public funderAddresses; //this will be an array of the addresses of the funders making it easier to iterate through them

    bytes32[] public thresholdCrossedSubmissions; //this will be an array of the submissions that have crossed the threshold

    mapping (address => bool) public admins; //this will be a mapping of the addresses of the admins to a boolean value of true or false

    uint256 public total_funds; //this will be the total amount of funds raised

    uint256 public total_rewards; //this will be the total amount of rewards available

    uint256 public platform_reward; //this will be the amount of rewards that the platform will receive

    bool public distributed; //this will be a boolean value of true or false to determine if the rewards have been distributed


    SubmissionAVLTree private submissionTree; //this will be the submission tree coming from the SubmissionAVLTree contract

    // Add a new mapping to store each funder's votes on each submission
    mapping(address => mapping(bytes32 => uint256)) public funderVotes; 

    mapping(bytes32 => mapping(address => bool)) public refunded; //this will be a mapping of the submissions to the addresses of the funders to a boolean value of true or false to determine if they have been refunded

    
    //events
    event DebugDistributeRewards(uint256 indexed totalRewards, uint256 indexed votes);

    event RefundInfo(uint256 refundAmount, uint256 totalRefundAmount);




    constructor(address submissionContract) {
        //add as many admins as you need to -- replace msg.sender with the address of the admin(s) for now this means the deployer will be the sole admin
        admins[msg.sender] = true;
        admins[0xcd258fCe467DDAbA643f813141c3560FF6c12518] = true;
        // Initialize the submissionTree
        submissionTree = SubmissionAVLTree(submissionContract); 
    }


        //create a function to start the submission period
    function start_submission_period(uint256 _submission_time) public {
        require(admins[msg.sender] == true, "You are not an admin");
        submission_time = block.timestamp + _submission_time * 1 days;
        //submission time will be in days
    }

    //getter for submission time
    function get_submission_time() public view returns (uint256) {
        return submission_time;
    }

    //getter for voting time
    function get_voting_time() public view returns (uint256) {
        return voting_time;
    }

    //end the submission period
    function end_submission_period() public {
        require(admins[msg.sender] == true, "You are not an admin");
        submission_time = 0;
    }

    //start the voting period
    function start_voting_period(uint256 _voting_time) public {
        require(admins[msg.sender] == true, "You are not an admin");
        require (block.timestamp > submission_time, "Submission period has not ended");
        voting_time = block.timestamp + _voting_time * 1 days;
        //voting time also in days
    }

    //end the voting period
    function end_voting_period() public {
    require(admins[msg.sender] == true, "You are not an admin");
    voting_time = 0;
    distributeRewards();

}

//Distribute rewards
function distributeRewards() private {
    require(admins[msg.sender] == true, "You are not an admin");
    require(distributed == false, "Rewards have already been distributed");
    SubmissionAVLTree.SubmissionInfo[] memory allSubmissions = getAllSubmissions();

    platform_reward = (total_funds * 5) / 100;

    // Count the number of funded submissions and add them to the fundedSubmissions array
    for (uint256 i = 0; i < allSubmissions.length; i++) {
        if (allSubmissions[i].funded) {
        uint256 reward = (allSubmissions[i].votes * 95) / 100;
        total_rewards -= reward;
        payable(allSubmissions[i].submitter).transfer(reward);
        }
    }

    total_rewards = 0;

    // Send the platform reward
    payable(PLATFORM_ADDRESS).transfer(platform_reward);
    platform_reward = 0;

    distributed = true;

}

//update threshhold
function updateThresholdStatus(bytes32 _submissionHash) internal {
    SubmissionAVLTree.SubmissionInfo memory submission = submissionTree.getSubmission(_submissionHash);
    if (!submission.funded && submission.votes >= submission.threshhold) {
        submissionTree.setThresholdCrossed(_submissionHash, true);
        thresholdCrossedSubmissions.push(_submissionHash);
    }
}

//addSubmission should return the submissionHash
function addSubmission(address submitter, string memory submissionText, uint256 threshold) public returns (bytes32) {
    require(block.timestamp < submission_time, "Submission period has ended");
    bytes32 submissionHash = keccak256(abi.encodePacked(submitter, submissionText));
    submissionTree.add_submission(submitter, submissionHash, submissionText, threshold);
    return submissionHash;
}

    //create a function to allow funders to vote for a submission
    // Update the vote function
    function vote(bytes32 _submissionHash, uint256 amount) public {
        require(block.timestamp < voting_time, "Voting period has ended");
        require(amount <= funders[msg.sender], "You do not have enough funds to vote this amount");

        funders[msg.sender] -= amount;

        SubmissionAVLTree.SubmissionInfo memory submissionCheck = submissionTree.getSubmission(_submissionHash);
        //submission should return a struct with the submissionHash, the submitter, the submissionText, the threshhold, the votes, and the funded status -- check if the submission hash is in the tree
        require(submissionCheck.submissionHash == _submissionHash, "Submission does not exist");

        submissionTree.addVotes(_submissionHash, amount);
        funderVotes[msg.sender][_submissionHash] += amount;

        submissionTree.updateFunderBalance(_submissionHash, msg.sender, (funderVotes[msg.sender][_submissionHash]*95)/100);



        SubmissionAVLTree.SubmissionInfo memory submission = submissionTree.getSubmission(_submissionHash);
        if (submission.votes >= submission.threshhold) {
        submissionTree.setThresholdCrossed(_submissionHash, true);
    }
    }

    //Change_votes should now stop folks from being able to change someone elses vote
    function change_vote(bytes32 _previous_submissionHash, bytes32 _new_submissionHash, uint256 amount) public {
        require(block.timestamp < voting_time, "Voting period has ended");
        require(funderVotes[msg.sender][_previous_submissionHash] >= amount, "You do not have enough votes on the previous submission from this address");


        submissionTree.subVotes(_previous_submissionHash, amount);
        submissionTree.addVotes(_new_submissionHash, amount);
        submissionTree.updateFunderBalance(_previous_submissionHash, msg.sender, (funderVotes[msg.sender][_previous_submissionHash]*95)/100);
        submissionTree.updateFunderBalance(_new_submissionHash, msg.sender, (funderVotes[msg.sender][_new_submissionHash]*95)/100);

        funderVotes[msg.sender][_previous_submissionHash] -= amount;
        funderVotes[msg.sender][_new_submissionHash] += amount;

        SubmissionAVLTree.SubmissionInfo memory previousSubmission = submissionTree.getSubmission(_previous_submissionHash);
        if (previousSubmission.votes < previousSubmission.threshhold) {
        submissionTree.setThresholdCrossed(_previous_submissionHash, false);

        
        }

        SubmissionAVLTree.SubmissionInfo memory newSubmission = submissionTree.getSubmission(_new_submissionHash);
        if (newSubmission.votes >= newSubmission.threshhold) {
        submissionTree.setThresholdCrossed(_new_submissionHash, true);
        }
        }

    //uses functionality of the AVL tree to get all submissions
    function getAllSubmissions() public view returns (SubmissionAVLTree.SubmissionInfo[] memory) {
        return submissionTree.inOrderTraversal();
    }

    //function to allow funders to add funds to the contract
    function addFunds() public payable {
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
    function use_unused_votes(bytes32 _submissionHash) public {
    require(admins[msg.sender] == true, "You are not an admin");
    require(block.timestamp < voting_time, "Voting period has ended");


    uint256 unused_admin_votes = total_funds - total_rewards;
    submissionTree.addVotes(_submissionHash, unused_admin_votes);
    unused_admin_votes = 0;
}

//Allows users to withdraw funds that they have voted for but did not cross threshhold
function claimRefund(address recipient) public {
    // Make sure to add necessary require statements for authorization and timing
    require(admins[msg.sender] == true, "You are not an admin");
    require(block.timestamp > voting_time, "Voting period has not ended");
    SubmissionAVLTree.SubmissionInfo[] memory allSubmissions = getAllSubmissions();

    uint256 totalRefundAmount = 0;

    // Count the number of funded submissions and add them to the fundedSubmissions array
    for (uint256 i = 0; i < allSubmissions.length; i++) {
        if (!allSubmissions[i].funded) {
            uint256 refundAmount = submissionTree.submissionFunderBalances(allSubmissions[i].submissionHash, recipient);
            require(refundAmount > 0, "No refundable amount found");
            require(!refunded[allSubmissions[i].submissionHash][recipient], "Refund already claimed");

            refunded[allSubmissions[i].submissionHash][recipient] = true;
            totalRefundAmount += refundAmount;
        }
    }

    total_funds -= totalRefundAmount;
    payable(recipient).transfer(totalRefundAmount);
    emit RefundInfo(totalRefundAmount, total_funds);
}

//Simple view functions to check the refund amount
function check_refund_amount(address recipient) public view returns (uint256 _refundAmount) {
    require(admins[msg.sender] == true, "You are not an admin");
    require(block.timestamp > voting_time, "Voting period has not ended");
    SubmissionAVLTree.SubmissionInfo[] memory allSubmissions = getAllSubmissions();


    // Count the number of funded submissions and add them to the fundedSubmissions array
    for (uint256 i = 0; i < allSubmissions.length; i++) {
        if (!allSubmissions[i].funded) {
            uint256 refundAmount = submissionTree.submissionFunderBalances(allSubmissions[i].submissionHash, recipient);
            //0.9 Eth to wei
            return refundAmount;
        }
    }
}



    //create function for admins to withdraw funds to the platform
    function withdraw_platform_funds() public {
        require(admins[msg.sender] == true, "You are not an admin");
        require(block.timestamp > voting_time, "Voting period has not ended");
        require(distributed == true, "Rewards have not been distributed");

        //transfer any dust or balance to platform 
        uint256 platform_balance = address(this).balance;

        payable(PLATFORM_ADDRESS).transfer(platform_balance);
    }


    
}
