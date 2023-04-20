// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SubmissionAVLTree {



    mapping (address => bool) public admins; 

    mapping(bytes32 => mapping(address => uint256)) public submissionFunderBalances; //is equal to funderVotes for testing purposes

    address[] public funderAddresses; 
    mapping(address => bool) public hasFunded; //bool may not be required 


//Struct for submission info in addition to parameters used by AVL tree
    struct SubmissionInfo {
        bytes32 submissionHash;
        uint256 votes;
        address submitter;
        uint256 threshhold;
        bool funded;
        int256 height;
        uint256 left;
        uint256 right;
    }




//Array of submissions and root of AVL tree
    SubmissionInfo[] public submissions;
    uint256 public root;

    //AVL tree functions
    function height(uint256 node) private view returns (int256) {
        if (node == 0) {
            return -1;
        }
        return submissions[node].height;
    }

    function updateHeight(uint256 node) private {
        submissions[node].height = 1 + max(height(submissions[node].left), height(submissions[node].right));
    }

    function max(int256 a, int256 b) private pure returns (int256) {
        return a > b ? a : b;
    }

    function balanceFactor(uint256 node) private view returns (int256) {
        return height(submissions[node].left) - height(submissions[node].right);
    }

    function rotateLeft(uint256 node) private returns (uint256) {
        uint256 pivot = submissions[node].right;
        submissions[node].right = submissions[pivot].left;
        submissions[pivot].left = node;
        updateHeight(node);
        updateHeight(pivot);
        return pivot;
    }

    function rotateRight(uint256 node) private returns (uint256) {
        uint256 pivot = submissions[node].left;
        submissions[node].left = submissions[pivot].right;
        submissions[pivot].right = node;
        updateHeight(node);
        updateHeight(pivot);
        return pivot;
    }

    function balance(uint256 node) private returns (uint256) {
        int256 balanceFactorNode = balanceFactor(node);

        if (balanceFactorNode > 1) {
            if (balanceFactor(submissions[node].left) < 0) {
                submissions[node].left = rotateLeft(submissions[node].left);
            }
            node = rotateRight(node);
        } else if (balanceFactorNode < -1) {
            if (balanceFactor(submissions[node].right) > 0) {
                submissions[node].right = rotateRight(submissions[node].right);
            }
            node = rotateLeft(node);
        } else {
            updateHeight(node);
        }
        
        return node;
    }

    //Adding a submission to the AVL tree
    function add_submission(address submitter, bytes32 submissionHash, string memory submissionText, uint256 threshold) external {
        uint256 newNodeIndex = submissions.length;
        submissions.push(SubmissionInfo(submissionHash, 0, submitter, threshold, false, 0, 0, 0));

        if (newNodeIndex == 0) {
            root = newNodeIndex;
        } else {
            root = insert(root, newNodeIndex);
        }
    }

    //Updating the funder balance for a submission
    function updateFunderBalance(bytes32 _submissionHash, address funder, uint256 balances) public {
    submissionFunderBalances[_submissionHash][funder] = balances;
    if (!hasFunded[funder]) {
        funderAddresses.push(funder);
        hasFunded[funder] = true;
    }
}



    //AVL tree function
    function insert(uint256 node, uint256 newNode) private returns (uint256) {
        if (node == 0) {
            return newNode;
        }

        if (submissions[newNode].submissionHash < submissions[node].submissionHash) {
            submissions[node].left = insert(submissions[node].left, newNode);
        } else if (submissions[newNode].submissionHash > submissions[node].submissionHash) {
            submissions[node].right = insert(submissions[node].right, newNode);
        } else {
            // Duplicate submissionHash, do nothing
            return node;
        }

        return balance(node);
    }

    //Finder function to find submission by hash bytes32
    function findSubmission(bytes32 submissionHash) public view returns (uint256) {
        return find(root, submissionHash);
    }
    
    //get submission by hash bytes32 and return memory struct
    function getSubmission(bytes32 submissionHash) public view returns (SubmissionInfo memory) {
        uint256 node = find(root, submissionHash);
        return submissions[node];
    }

    //get all submissions and return memory struct
    function getAllSubmissions () public view returns (SubmissionInfo[] memory) {
        return submissions;
    }

    //AVL tree function to find submission by hash bytes32 and uint256 node
    function find(uint256 node, bytes32 submissionHash) private view returns (uint256) {
        if (node == 0) {
            return 0;
        }

        if (submissions[node].submissionHash == submissionHash) {
            return node;
        }

        if (submissions[node].submissionHash > submissionHash) {
            return find(submissions[node].left, submissionHash);
        } else {
            return find(submissions[node].right, submissionHash);
        }
    }

    //thresholdCrossed is a function that returns true if the number of votes is greater than or equal to the threshold, and takes in a submissionhash
    function thresholdCrossed(bytes32 submissionHash) public view returns (bool) {
        uint256 node = find(root, submissionHash);
        return submissions[node].votes >= submissions[node].threshhold;
    }

    //setThresholdCrossed also takes in a submissionhash and sets the funded boolean to true
    function setThresholdCrossed(bytes32 submissionHash, bool status) public {
        uint256 node = find(root, submissionHash);
        submissions[node].funded = status;
    }

    //addVotes and subVotes are functions that add and subtract votes from a submission
    function addVotes(bytes32 submissionHash, uint256 votes) public {
        uint256 node = find(root, submissionHash);
        submissions[node].votes += votes;
    }

    function subVotes(bytes32 submissionHash, uint256 votes) public {
        uint256 node = find(root, submissionHash);
        submissions[node].votes -= votes;
    }

    //function to get the number of submissions by navigating the AVL tree
    function inOrderTraversal() public view returns (SubmissionInfo[] memory) {
        bytes32[] memory submissionHashes = new bytes32[](submissions.length);
        inOrderTraversalHelper(root, submissionHashes, 0);
        SubmissionInfo[] memory submissionInfo = new SubmissionInfo[](submissions.length);
        for (uint256 i = 0; i < submissions.length; i++) {
            submissionInfo[i] = submissions[find(root, submissionHashes[i])];
        }
        return submissionInfo;
    }


    //inOrderTraversalHelper is a helper function for inOrderTraversal inOrderTraversalHelper(node, submissionHashes, index)
    function inOrderTraversalHelper(uint256 node, bytes32[] memory submissionHashes, uint256 index) private view {
        if (node == 0) {
            return;
        }

        inOrderTraversalHelper(submissions[node].left, submissionHashes, index);
        submissionHashes[index] = submissions[node].submissionHash;
        index++;
        inOrderTraversalHelper(submissions[node].right, submissionHashes, index);
    }

    //getByindex should return memory
    function getByIndex(uint256 index) public view returns (SubmissionInfo memory) {
        return submissions[index];
    }




}
