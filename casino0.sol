pragma solidity ^0.4.24;

contract Casino{

	struct Option {
		uint optionReward;
		BetInfo[] betInfo;
	}

	struct BetInfo {
		address betAddress;
		uint amount;
	}

	Option[2] public options;
	uint public bettingTime;
	uint public totalReward;
	uint public winner;
	bool public winnerRevealed;

	Option tempOption;
	BetInfo tempBetInfo;

	// Stage 0: Create
	// Initialize
	constructor (uint _betTimePeriodInMinutes) public {
		bettingTime = now + _betTimePeriodInMinutes * 1 minutes;
		winnerRevealed = false;
	}

	// Stage 1: Betting
	function bet(uint _option) public payable {
		require(now <= bettingTime);
		require(_option < options.length);
		options[_option].betInfo.push(BetInfo(msg.sender, msg.value));
		options[_option].optionReward += msg.value;
		totalReward += msg.value;
	}

	// Stage 2: Getting Result
	function getResult() public {
		require(now >= bettingTime);
		require(!winnerRevealed);
		winner = 1;  //fixed winner
		winnerRevealed = true;
	}

	// Stage 3: Dispatch the reward
	function dispatch() public {
		require(winnerRevealed);
		assert(winner < options.length);

		for(uint256 i = 0; i < options[winner].betInfo.length; i++){
			address receiver = options[winner].betInfo[i].betAddress;
			uint256 value = totalReward * options[winner].betInfo[i].amount / options[winner].optionReward;
			require(receiver.send(value));
		}
	}
}