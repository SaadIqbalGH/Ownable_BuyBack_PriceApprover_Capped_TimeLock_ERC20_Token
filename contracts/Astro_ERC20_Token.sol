pragma solidity ^0.8.0;
//"SPDX-License-Identifier: UNLICENSED"

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Astro_ERC20_Token is ERC20, Ownable, AccessControl {
    
    using SafeMath for uint256;

    uint256 public _cap;
    uint256 public initialSupply;
    uint256 public releaseTime;
    uint256  public Token_Sale_Lot; 
    uint256  public Lot_Sell_Price;
    uint256 internal numToken;
    address public _Owner;
    bytes32 public  PRICE_APPROVER_ROLE = keccak256("PRICE_APPROVER_ROLE");
    
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) internal _balances_onHold;
    event Lot_Sell_Price_Changed(address updater, uint256 newPrice);
    event tokenPending(string info, uint256 tokens_num );
    
    constructor() ERC20("Astro Token", "AT") {
        initialSupply = 500000 * (10**uint256(decimals()));
        _cap = initialSupply.mul(20000);
        releaseTime = block.timestamp + 1 minutes; // setting 1 min for testing - later would be converted to 30 days
        _Owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, _Owner);
        _mint(msg.sender, initialSupply); 
        _balances[_Owner] = totalSupply();
        Token_Sale_Lot = 100 * (10**uint256(decimals()));
        Lot_Sell_Price = 1000000000000000000  wei;
    }
    
    function generateToken(address account, uint256 _Tokens) public onlyOwner {
        require(account != address(0), "Invalid zero address!");
        require(_Tokens > 0, "Invalid amount");
        require(totalSupply().add(_Tokens) <= _cap, "Overlimit: amount exceeded capped value, Token generation failed");
        _mint(account,_Tokens);
    }
    
    //Assumption:The buyer will buy the token only once during token hold period
    
    function buyToken () public payable {

        require(Lot_Sell_Price > 0,"Invalid sell price declaration!");
        require(msg.value > 0, "Insufficient funds to buy Tokens");
        
        numToken = (msg.value.mul(Token_Sale_Lot)).div(Lot_Sell_Price);
        require(numToken <= _balances[_Owner],"Not enough tokens to sell, report issue to owner");
       _balances_onHold[msg.sender] = numToken;
       emit tokenPending("Your tokens are time locked, though you have purchaed total CLT tokens: ", numToken);
        
    }
      //Assumption:The buyer will buy the token only once during token hold period - this is assumed to avoid complexity 
      
    function transfer(address beneficiary, uint256 lockedTokens) public  onlyOwner virtual override returns (bool) {
        require(lockedTokens == _balances_onHold[beneficiary], "Please enter correct number of locked tokens.");
        require(block.timestamp >= releaseTime, "Token is time locked or no pending token to issue");
        _balances_onHold[beneficiary] = 0;
        super.transfer(beneficiary, lockedTokens);
        return true;
    }
  
     // to collect ether recived on contract's address
    receive() external payable { 
        
    }
    
    function changeListPrice(uint256 _newListPrice) public {
        require(hasRole(PRICE_APPROVER_ROLE, msg.sender) || (msg.sender == _Owner), "Caller is not authorized to change the token price");
	    Lot_Sell_Price = _newListPrice;
	    
	    emit Lot_Sell_Price_Changed(msg.sender, _newListPrice);
	}
 
    function tokenReturn (uint256 claimed_CLT) public returns (bool){
        _balances[msg.sender] = balanceOf(msg.sender);
        _balances[_Owner] = balanceOf(_Owner);
        require ((msg.sender != _Owner) && (msg.sender != address(0)), "Only customers can return the tokens");
        require (_balances[msg.sender] >= claimed_CLT, "Claimed tokens are higher than caller's current balance");        
        ERC20._transfer(msg.sender, _Owner, claimed_CLT);
        _token_return(claimed_CLT); 
        return true;
        
    }
    
    function _token_return (uint256 _claimed_CLT) internal {
        uint256 _refund_amount = 0;
        _refund_amount = (_claimed_CLT.div(Token_Sale_Lot)).mul(Lot_Sell_Price);
        require(address(this).balance >= _refund_amount, "Insufficient ether balance, please contact contract owner");
        payable(msg.sender).transfer(_refund_amount);
        emit Transfer(address(this), msg.sender, _refund_amount);        
    }
        
    fallback() payable external{
        buyToken ();
        
    }
    
    // to check current ether total balance of the contract
    function getEtherBalCon() public view returns (uint256) {
        return address(this).balance;
    }

}