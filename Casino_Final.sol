pragma solidity ^0.4.24;

contract Token{
    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public tokenOwnerAdderss;
    address public casinoAddress;
    
    modifier onlyBy(address _owner){
        require(msg.sender == _owner);
        _;
    }
    
    constructor(address _tokenOwner) public {
        totalSupply = 0;
        tokenOwnerAdderss = _tokenOwner;
        casinoAddress = msg.sender;
    }
    
    function transfer(address _to, uint256 _value) public returns(bool){
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[msg.sender] -= _value;
        
        return true;
    }
    
    function transferByCasino(address _from, address _to, uint256 _value) public onlyBy(casinoAddress) returns(bool){
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(balanceOf[_from] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        
        return true;
    }
    
    function mint(address _to, uint256 _value) public onlyBy(tokenOwnerAdderss){
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_to] += _value;
        totalSupply += _value;
    }
    
}

contract Casino{
    
    struct Option{
        uint optionReward; 
        mapping (address => uint256) betInfo;
    }
    
    Token token;
    address public tokenAddress;
    address public casinoOwnerAdderss;
    uint256 public bettingTime;
    bool public winnerRevealed;
    
    uint256 public totalReward;
    Option[2] options;
    
    uint256 public winner;
    
    event WinnerIs(uint256 _winner);
    event BetSuccess(address _player, uint256 _option, uint256 _value);
    event GetReward(address _player, uint256 _reward);
    
    
    modifier onlyBy(address _owner){
        require(msg.sender == _owner);
        _;
    }

    // Stage 0: Create
    // Initialize
    constructor(uint256 _bettingTimeInMinutes) public {
        casinoOwnerAdderss = msg.sender;
        bettingTime = now + _bettingTimeInMinutes * 1 minutes;
        winnerRevealed = false;

        tokenAddress = new Token(msg.sender);
        token = Token(tokenAddress);    
    }
    
    // Stage 1: Betting
    function bet(uint256 _option, uint256 _value) public returns (bool){
        require(now <= bettingTime);
        require(_option < options.length);
        require(token.transferByCasino(msg.sender, this, _value));
        
        options[_option].betInfo[msg.sender] += _value;
        options[_option].optionReward += _value;
        totalReward += _value;
        
        emit BetSuccess(msg.sender, _option, _value);
        return true;
    }
    
    // Stage 2: Getting Result
    function revealWinner() public {
        require(now > bettingTime);
        require(!winnerRevealed);
        winner = uint(keccak256(abi.encodePacked(block.timestamp))) % 2;
        winnerRevealed = true;

        emit WinnerIs(winner);
    }
    
    // Stage 3: Claim the reward
    function claimReward() public returns (bool){
        require(winnerRevealed);
        assert(winner < options.length);
        require(options[winner].betInfo[msg.sender] != 0);
        
        uint reward = totalReward * options[winner].betInfo[msg.sender] / options[winner].optionReward;
        options[winner].betInfo[msg.sender] = 0;
        require(token.transfer(msg.sender, reward));
        
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