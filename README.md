## VIAPRIZE

# Decentralized Voting System

A decentralized voting system built on the Ethereum blockchain, allowing for secure and transparent voting on various submissions. This smart contract manages the submission of proposals, voting, funding, and admin management using an AVL tree data structure for efficient storage and retrieval. This is considered a Dominant Assurance Contract, where if target funding is crossed by a deadline (voting period) then funded submissions can be paid out. Otherwise, any funds/votes for a submission that did not meet it's funded target are elligible for a refund (minus tx fees/platform fee of 5%)

# Features

- Admin-controlled submission process.
- Secure and transparent voting.
- Voting power allocation for funders.
- Threshold-based funding for submissions.
- Unused voting power redistribution. !! needs convo - might remove feature
- Time-based voting period.
- AVL tree implementation for efficient submission storage and retrieval.


# Smart Contract Functions Viaprize.sol

* submit_proposal(string memory _proposal)
* Submits a proposal to the system.

* vote(uint _submission, bool _vote)
* Allows users to vote on a specific submission. Funds = voting power

* use_unused_votes(uint _submission)
* Allows admins to redistribute their unused voting power to a specific submission. (might remove this)

* end_voting_period()
* Ends the voting period, preventing further voting or proposal submissions - distributes funds to funded submissions and 5% to platform. Can only be calledby     
  the contract owner.

# Smart Contract Functions SubmissionAVLTree.sol

* updateFunderBalance(bytes32 _submissionHash, address funder, uint256 balances)
* Updates the funder's balance for a specific submission.

* addVotes(bytes32 submissionHash, uint256 votes)
* Allows users to vote on a specific submission.

* subVotes(bytes32 submissionHash, uint256 votes)
* Allows users to remove votes from a specific submission.

* thresholdCrossed(bytes32 submissionHash)
* Returns true if the number of votes is greater than or equal to the threshold.

* setThresholdCrossed(bytes32 submissionHash, bool status)
* Sets the funded status of a submission.

* findSubmission(bytes32 submissionHash)
* Returns the index of a submission in the AVL tree.

* getSubmission(bytes32 submissionHash)
* Returns a submission's information given its hash.

* getAllSubmissions()
* Returns an array of all submissions.

* inOrderTraversal()
* Returns an array of all submissions sorted by their submission hash.

* getByIndex(uint256 index)
* Returns a submission's information by its index in the AVL tree.


# Usage

Deploy the smart contract to the Ethereum network using a development framework such as Truffle or Hardhat.
Interact with the smart contract using a Web3 provider like MetaMask or a DApp frontend.
Requirements

# To-Do

 + Update submission and voting period: Implement a method to update the submission and voting period to make it more flexible and dynamic.
 + Support for Dominant Assurance: Each submission should have a custom donation threshold that must be crossed for the submission to be considered.
 + Implement a refund mechanism for users if the threshold is not met (minus gas/network fees). Payout to the submission if the threshold is crossed.
 + Remove admin control: Make the contract unstoppable by removing admin restrictions on submission and other functions, relying on a decentralized governance model.
 + Contract Audit: Conduct a thorough smart contract audit to ensure security and reliability.

Solidity ^0.8.0
Web3.js or Ethers.js for frontend interaction (optional)
License

This project is released under the MIT License.