pragma solidity ^0.4.24;

contract Casino{

	struct Option{
        uint optionReward; 
        mapping (address => uint256) betInfo;
    }

	Option[2] public options;
	address public casinoOwnerAdderss;
	uint public bettingTime;
	uint public totalReward;
	uint public winner;
	bool public winnerRevealed;

	event WinnerIs(uint256 _winner);
    event BetSuccess(address _player, uint256 _option, uint256 _value);
    event GetReward(address _player, uint256 _reward);

	modifier onlyBy(address _owner){
        require(msg.sender == _owner);
        _;
    }

	// Stage 0: Create
	// Initialize
	constructor (uint _betTimePeriodInMinutes) public {
		casinoOwnerAdderss = msg.sender;
		bettingTime = now + _betTimePeriodInMinutes * 1 minutes;
		winnerRevealed = false;
	}

	// Stage 1: Betting
	function bet(uint _option) public payable returns (bool){
		require(now <= bettingTime);
		require(_option < options.length);
		
		options[_option].betInfo[msg.sender] += msg.value;
		options[_option].optionReward += msg.value;
		totalReward += msg.value;

		emit BetSuccess(msg.sender, _option, msg.value);
		return true;
	}

	// Stage 2: Getting Result
	function revealWinner() public{
		require(now >= bettingTime);
		require(!winnerRevealed);		
		winner = uint(keccak256(abi.encodePacked(block.timestamp))) % 2;
		winnerRevealed = true;

		emit WinnerIs(winner);
	}

	// Stage 3: Dispatch the reward
	function claimReward() public returns (bool){
		require(winnerRevealed);
		assert(winner < options.length);
		require(options[winner].betInfo[msg.sender] != 0);

		uint reward = totalReward * options[winner].betInfo[msg.sender] / options[winner].optionReward;
		options[winner].betInfo[msg.sender] = 0;
		
		require(msg.sender.send(reward));
		emit GetReward(msg.sender, reward);
		return true;
	}

	// Owner function
	function setBettingTime(uint256 _newBettingTimeInSecond) public onlyBy(casinoOwnerAdderss){
        bettingTime = _newBettingTimeInSecond;
    }

	// Helper function
	function showWinner() view public returns(string){
		if(!winnerRevealed) return "Waiting for a winner";
		else{
        	require(winner == 0 || winner == 1);
        	
        	if(winner == 0) return "The winner is number 0.";
        	else if(winner == 1) return "The winner is number 1.";
		}
	} 
}