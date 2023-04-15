// SPDX-License-Identifier: MIT

//this contract is to track and store passport scores for specific users based on their community involvement.
//The scores are obtained through an API call to a specific endpoint, which is passed in as a constructor argument along with an API key.

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GitcoinPassport is ChainlinkClient, Ownable {
    mapping(address => uint256) public scores;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    string private apiKey;
    string private apiEndpoint;

    constructor(string memory _apiKey, string memory _apiEndpoint) {
        setPublicChainlinkToken();
        oracle = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455; // Oracle address
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8"; // Job ID
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        apiKey = _apiKey;
        apiEndpoint = _apiEndpoint;
    }

    function requestPassportScore(address user, string memory communityId) public onlyOwner returns (bytes32 requestId) {
        string memory finalEndpoint = string(abi.encodePacked(apiEndpoint, communityId, "/", user));
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillPassportScore.selector); // Updated docs for chainlink oracle, syntax no longer valid
        request.add("get", finalEndpoint);
        request.addHeader("Authorization", string(abi.encodePacked("Bearer ", apiKey))); // Use the API key passed in the constructor
        request.add("path", "data.score");
        request.addInt("times", 100);
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    // Updated docs for chainlink oracle, syntax no longer valid in above function, may use external chainlink adapter to retrive values


    function fulfillPassportScore(bytes32 _requestId, uint256 _score) public recordChainlinkFulfillment(_requestId) {
        scores[msg.sender] = _score;
    }

    function getPassportScore(address user) public view returns (uint256) {
        return scores[user];
    }
}
