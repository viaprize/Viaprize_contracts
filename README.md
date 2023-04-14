## VIAPRIZE

# Decentralized Voting System

A decentralized voting system built on the Ethereum blockchain, allowing for secure and transparent voting on various submissions. This smart contract manages the submission of proposals, voting, and admin management.

# Features

- Admin-controlled submission process.
- Secure and transparent voting.
- Voting power allocation for admins.
- Unused voting power redistribution.
- Time-based voting period.

# Smart Contract Functions

* submit_proposal(string memory _proposal)
* Submits a proposal to the system. Can only be called by admins.

* vote(uint _submission, bool _vote)
* Allows users to vote on a specific submission. Users can vote 'yes' or 'no'.

* use_unused_votes(uint _submission)
* Allows admins to redistribute their unused voting power to a specific submission.

* end_voting_period()
* Ends the voting period, preventing further voting or proposal submissions. Can only be called by the contract owner.

* add_admin(address _newAdmin)
* Adds a new admin to the system. Can only be called by the contract owner.

* remove_admin(address _admin)
* Removes an admin from the system. Can only be called by the contract owner.

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