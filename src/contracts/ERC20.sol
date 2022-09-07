// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
interface ERC20Interface{
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to,uint tokens) external returns(bool success);


     function allowance(address tokenOwner,address spender) external view returns(uint remaining);
     function approve(address spender,uint tokens) external returns (bool success);
     function tranferFrom(address from,address to,uint tokens) external returns (bool success);


    event Transfer(address indexed from, address indexed to, uint token);
    event Approval(address indexed tokenOwner,address indexed spender,uint tokens);



}


contract ERC20 is ERC20Interface{
    
    string public name = "Cryptos";
    string public symbol= "CRPT";
    uint public decimals = 0; //18
    // total supply - represent the toral number of tokens
    uint public override totalSupply; // a getter function will be created bcz the variable is public

    address public founder;
    // map to store each address and no of tokens with respect to it
    mapping(address=>uint) public balances;
   

   constructor(){
    totalSupply= 1000000;
    founder = msg.sender;
    balances[founder] = totalSupply;
   }


// first - this mapping includes the accounts approved tp withdraw from a 
// account together with the withdrawal sum allowed for wach of them

// first mapping is the key - the address of the token holder
// second map inside it - is representing the addresses that are allowed to transfer

   mapping(address=>mapping(address=>uint)) public allowed;


      function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
      }
  
 function transfer(address to,uint tokens) public virtual override returns(bool success){
      
       require(balances[msg.sender]>=tokens,"not enough balance available to tranfer");
       
       balances[to] +=tokens;
       balances[msg.sender] -= tokens;

       emit Transfer(msg.sender, to, tokens);
       return true;
 }



 // it allows the spender to withdraw and transfer from the
 // owners account multiple times upto the allowance
 // this function will also change the current allowance
 // func - will only be called by the account that was allowed to
 // transfer token from the holders accounts to his own or to another

 

 function tranferFrom(address from,address to,uint tokens) public virtual override returns (bool success){
    // checking the allowance of curent user - who call this function
    // is greater and equal to tokens
    
    require(allowed[from][msg.sender]>=tokens);
    require(balances[from]>= tokens);
    balances[from] -= tokens;
    allowed[from][msg.sender] -=tokens;
    balances[to] += tokens;
    emit Transfer(from, to, tokens);
    return true;
  }
   function allowance(address tokenOwner,address spender) public view override returns(uint remaining){
    return allowed[tokenOwner][spender];
   }


// this functiokn will be called by token owner to set the allowance
// which is the ammount that can be spent by the spender of this account

  function approve(address spender,uint tokens) public  override returns (bool success){
     require(balances[msg.sender] >= tokens);
     require(tokens>0); 
     allowed[msg.sender][spender] = tokens;
  
     emit Approval(msg.sender, spender, tokens);
     return true;
  }



     

    


}

contract CryptosICO is ERC20{
    // admin - who deploys the contract
    // -if any emergency or can change the deposit if it gets compromised

     address public admin;

     // investor will send eth to contract address
     // the ether will automictaically transfer to deposit address
     // and the cryptos will be added to the balance of investor
     address payable public deposit;

     // set token price - 1000crypt for 1 ether
     uint tokenPrice = 0.001 ether;

     // hardcap - maximum amount of ether that can be invested
     uint public hardcap = 300 ether;

     // raisedAmount - total amount of ether sent to the ICO
     uint public raisedAmount;

   // iCo will start in 20 seconds after the deployment
     uint public saleStart = block.timestamp + 20;

     uint public saleEnd = block.timestamp + 604800;

    // set token to tranfer only after a time after the Ico
    // ends so that the early investors can not dump the tokens on the market, 
    // causing the price to collapse
    uint public tokenTradeStart = saleEnd + 604800; // transferable in a week after sale
     
    // maximmum and minimum investment
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;

    enum State{beforeStart, running , afterEnd, halted}
    
    State public icoState;


    constructor(address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;

    }

    modifier onlyAdmin(){
        require(msg.sender==admin);
        _;
    }
   // this function only called by admin to stop the ico at any moment

    function halt() public onlyAdmin{
        icoState= State.halted;

    }


    function resume() public onlyAdmin{
          icoState= State.running;
    }
   


   // function called only by admin to change the deposit address
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    } 
   

   // function to return the state of ICO
   

   function getCurrentState() public view returns(State){
      if(icoState==State.halted){
        return State.halted;
      }else if(block.timestamp<saleStart){
        return State.beforeStart;
      }else if(block.timestamp>= saleStart && block.timestamp <= saleEnd){
        return State.running;
      }else{
        return State.afterEnd;
      }
   }

   event Invest(address investor,uint value, uint tokens);

   // main function of the Ico - invest
   // call- when somebody sends eth to the contract
   // and recieves cryptos in return
    
    function invest() payable public returns(bool){
         // first check that the ico is in the running state
      icoState= getCurrentState();
      require(icoState == State.running);
      require(msg.value >= minInvestment && msg.value <= maxInvestment);
       
       // add the value into raised amount
      raisedAmount += msg.value;
      
      require(raisedAmount <= hardcap);


      // calculate the number of tokens user will get for the ether he has just sent
     
     uint tokens = msg.value/ tokenPrice;

     // now these tokens will be added to invester balance 
     // and subtracted from the founder balance

     balances[msg.sender] += tokens;
     balances[founder] -= tokens;
   

   // now transfer to the deposit address the amount of wei sent to the contract
   deposit.transfer(msg.value);

    emit Invest(msg.sender,msg.value,tokens);
    

  return true;
    }

    // the contract will accept eth that has sent to its address
    // if there is payable function called recieve

receive() payable external{
    // this function will automatically call when someone sends
    // ether to contact
    invest();
}


// we  need to override two function - from ERC20 contract
// transfer token and transferfrom

// with these function it is placing restriction -
// that if trade start then u can transfer tokens
function transfer(address to,uint tokens) public override returns(bool success){
   require(block.timestamp>tokenTradeStart);
    super.transfer(to, tokens); // also can use ERC20.transfer(to,token)
  
     return true;
 }


function tranferFrom(address from,address to,uint tokens) public override returns (bool success){
     require(block.timestamp>tokenTradeStart);
       ERC20.tranferFrom(from, to, tokens);
            return true;
  }


// burn the tokens that havent sold during Ico
// generaly burning tokens leads to increase in price
// burning means destroying them

// function can be call by anyone - this sures that admin does not change his mind
// and does not burn the token

// token will be burn only after the Iso ends
function burn() public returns(bool){
    icoState = getCurrentState();
    require(icoState== State.afterEnd);
    balances[founder]=0;
    return true;
}



}

