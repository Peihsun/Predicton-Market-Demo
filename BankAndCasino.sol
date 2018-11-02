pragma solidity ^0.4.24;

contract Bank{
    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public bankOwnerAdderss;
    address public casinoAddress;
    
    modifier onlyBy(address _owner){
        require(msg.sender == _owner);
        _;
    }
    
    constructor(address _bankOwner) public {
        totalSupply = 0;
        bankOwnerAdderss = _bankOwner;
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
    
    function mint(address _to, uint256 _value) public onlyBy(bankOwnerAdderss){
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_to] += _value;
        totalSupply += _value;
    }
    
}

contract Casino{
    
    struct Option{
        uint optionReward; 
        mapping (address => uint) betInfo;
    }
    
    Bank bank;
    address public bankAddress;
    uint public bettingTime;
    bool public winnerRevealed;
    
    uint public totalReward;
    Option[2] options;
    
    uint public winner;
    
    event WinnerIs(uint _winner);
    event BetSuccess(address _player, uint _option, uint _value);
    event GetReward(address _player, uint _reward);
    
    
    constructor(uint _bettingTimeInMinutes) public {
        bettingTime = now + _bettingTimeInMinutes * 1 minutes;
        
        bankAddress = new Bank(msg.sender);
        bank = Bank(bankAddress);
        
        winnerRevealed = false;
        
    }
    
    function bet(uint _option, uint _value) public returns (bool){
        require(now <= bettingTime);
        require(_option < options.length);
        require(bank.transferByCasino(msg.sender, this, _value));
        
        options[_option].betInfo[msg.sender] += _value;
        options[_option].optionReward += _value;
        totalReward += _value;
        
        emit BetSuccess(msg.sender, _option, _value);
        return true;
    }
    
    function revealWinner() public {
        require(now > bettingTime);
        require(!winnerRevealed);
        winner = uint(keccak256(abi.encodePacked(block.timestamp))) % 2;
        winnerRevealed = true;
        
        emit WinnerIs(winner);
    }
    
    function claimReward() public returns (bool){
        require(winnerRevealed);
        require(options[winner].betInfo[msg.sender] != 0);
        
        uint reward = totalReward * options[winner].betInfo[msg.sender] / options[winner].optionReward;
        options[winner].betInfo[msg.sender] = 0;
        require(bank.transfer(msg.sender, reward));
        emit GetReward(msg.sender, reward);
        
        return true;
    } 
    
    // helper funtion
    function showWinner() view public returns(string){
        if(!winnerRevealed) return "Waiting for a winner";
        else{
            assert(winner == 0 || winner == 1);
            
            if(winner == 0) return "The winner is number 0.";
            else if(winner == 1) return "The winner is number 1.";
        }
    }
}