pragma solidity ^0.8.0;

contract PrizeCompetition {
    address public owner;
    uint256 public deadline;
    uint256 public totalContributions;
    
    mapping(address => address) public votedFor;

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public votes;

    uint256 public votesForRefund;
    uint256 public votesForWinner;
    address public winner;

    uint256 public candidateCount;
    mapping(uint256 => address) public candidates;

    enum State { Active, Refund, Winner }
    State public state;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyContributors() {
        require(contributions[msg.sender] > 0, "Only contributors can call this function.");
        _;
    }

    modifier onlyBeforeDeadline() {
        // MOOSE
        require(block.timestamp < deadline, "Voting period has ended.");
        _;
    }

    modifier onlyAfterDeadline() {
        // MOOSE
        require(block.timestamp > deadline, "Voting period has ended.");
        _;
    }

    constructor(uint256 _deadline) {
        owner = msg.sender;
        deadline = _deadline;
        state = State.Active;
    }

    function contribute() external payable {
        require(state == State.Active, "Competition is not active.");

        // if you've already contributed, this cleans up your vote,
        // and votes again for the same
        if(votedFor[msg.sender]!=address(0)){
            address _winner = votes[votedFor[msg.sender]];
            removeVote();
            contributions[msg.sender] += msg.value;
            totalContributions += msg.value;
            vote(_winner);
        } else{
            contributions[msg.sender] += msg.value;
            totalContributions += msg.value;
        }
    }

    function removeVote() internal {
        uint256 numVotes = contributions[msg.sender];
        votedFor[msg.sender] =0;
        votes[votedFor_] -=numVotes;
    }

    function vote(uint256 _winner) public onlyContributors onlyBeforeDeadline {
        
        if(votedFor_[msg.sender]!=address(0)){
            removeVote();
        }

        uint256 numVotes = contributions[msg.sender];

        votedFor[msg.sender] = _winner;
        votes[_winner] += numVotes;
	}

    function addCandidate(address _candidate) onlyBeforeDeadline() {
        candidateCount+=1;
        candidates[candidateCount] = _candidate;
    }

    function endVoting() public onlyAfterDeadline {
        // declare winner

        // change the state to Winner or Refund

    }

    function claim() external {

        // make sure its not active

        // if its in Refund state, anyone can call it and get their money back.
        // make sure to delete the contributes BEFORE sending the eth

        // if its in Winner state, give the money to the winner
        
    }

}
