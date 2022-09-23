// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0<0.9.0;

contract Block {
   string public  name = "TC2";//name of the token
   string public  symbol  ="TC2";//Abbrevation of token
   uint8 public  decimals = 0;

 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint public  totalSupply;
    address public founder;
    mapping (address=>uint) public balances;
    mapping (address=>mapping(address=>uint)) allowed;
    constructor(){
        totalSupply = 1000000;
        founder =msg.sender;
        balances[founder] = totalSupply;
    }
    
   function balanceOf(address _owner) public view  returns (uint256 balance){
       return balances[_owner];
      }

function transfer(address _to, uint256 _value) public virtual  returns (bool success){
  require(balances[msg.sender]>= _value,"Not sufficient amount");
  balances[_to]+=_value; 
  balances[msg.sender]-=_value;
  emit Transfer(msg.sender, _to,_value);
  return true;
}
function approve(address _spender, uint256 _value) public  returns (bool success){
 require(balances[msg.sender]>=_value,"Not sufficient amount");
 require(_value>0);
 allowed[msg.sender][_spender]=_value;
 emit  Approval(msg.sender,_spender, _value);
 return true;
}
function allowance(address _owner, address _spender) public view  returns (uint256 remaining)
{
return allowed[_owner][_spender];
}
function transferFrom(address _from, address _to, uint256 _value) public virtual  returns (bool success)
{
    require(allowed[_from][_to]>=_value);
    require(balances[_from]>=_value);
    balances[_from]-=_value;
    allowed[_from][_to]-=_value;
    balances[_to]+=_value;
    return true;
}
}

contract ICO is Block{
   address public manager ;

   address payable public deposit;

   uint tokenPrice =0.1 ether;//price of one token
   
   uint public cap =300 ether;

   uint public raisedAmount;

   uint public icoStart  = block.timestamp;
   uint public icoEnd  = block.timestamp+3600;
   uint public tokenTradeTime  = icoEnd+3600;

   uint public maxInvest =100 ether;
   uint public minInvest  = .1 ether;

  enum State{beforeStart,afterEnd, running, halted}
  State public icoState;

  event Invest (address _investor, uint value, uint tokens);

  constructor(address payable _deposit){
      deposit  =_deposit;
      manager  = msg.sender;
      icoState = State.beforeStart;

  }

  modifier onlyManager(){
      require(msg.sender==manager);
      _;
  }
  function halt() public onlyManager{
      icoState = State.halted;
  }
  function resume() public onlyManager{
      icoState = State.running;
  } 
  function changeDepositeAddress(address payable newDeposit) public onlyManager{
      deposit = newDeposit;
  }
  function getState() public view returns(State){
      if(icoState==State.halted) {
          return State.halted; }
      else if(block.timestamp<icoStart){
          return State.beforeStart;
      }else if(block.timestamp>=icoStart && block.timestamp<=icoEnd) {
          return State.running;
      }else{
          return State.afterEnd;
      }
  }
  function invest() payable public returns (bool){
       icoState = getState();
       require(icoState ==State.running);
       require(msg.value>=minInvest && msg.value<=maxInvest);

       raisedAmount+=msg.value;
       require(raisedAmount<=cap);
       uint tokens = msg.value/tokenPrice;
       balances[msg.sender]+=tokens;
       balances[founder]-=tokens;
       deposit.transfer(msg.value);
       emit Invest(msg.sender,msg.value,tokens);
       return true;  
  }
  function burn() public returns(bool){
      icoState= getState();
      require(icoState==State.afterEnd);
      balances[founder]=0;
      return true;
  }
  function transfer(address to, uint tokens) public override returns (bool success){
   require(block.timestamp>tokenTradeTime)  ;
   super.transfer(to,tokens); 
   return true;
  }
  function transferFrom(address from, address to, uint tokens) public  override returns (bool success){
     require(block.timestamp>tokenTradeTime);
     super.transferFrom(from, to, tokens);
     return true;
  }
  receive() external payable {
    invest();
  }

}
