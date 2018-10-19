pragma solidity ^0.4.24;

contract Game{
    struct Option{
        uint totalGet;
        BetInfo[] betInfo;
    }
    
    struct BetInfo{
        address betAddress;
        uint amount;
    }
    
    Option[2] public options;
    uint public bettingDeadline;
    uint public totalReward;
    uint public winner;
    bool public haveResult;
    
    constructor (uint _betTimePeriotInMinutes){
        bettingDeadline = now + _betTimePeriotInMinutes * 1 minutes;
        haveResult = false;
    }
    
    function bet(uint _option) payable returns(bool){
        require(now < bettingDeadline);
        require(_option < options.length);
        
        options[_option].betInfo.push(BetInfo(msg.sender, msg.value));
        options[_option].totalGet += msg.value;
        totalReward += msg.value;
        return true;
    }
    
    function updateResult() returns (bool){
        require(now >= bettingDeadline);
        require(!haveResult);
        winner = 1;
        haveResult = true;
        return true;
    }
    
    function dispatchReward() returns (bool){
        require(haveResult);
        assert(winner < options.length);
        
        for(uint i; i < options[winner].betInfo.length; i++){
            address receiver = options[winner].betInfo[i].betAddress;
            uint receiverValue = totalReward*options[winner].betInfo[i].amount/options[winner].totalGet;
            options[winner].totalGet -= receiverValue;
            totalReward -= receiverValue;
            require(receiver.send(receiverValue));
        }
    }
    
    function stopBetting() returns (bool){
        bettingDeadline = now;
        return true;
    }
}