//Spendthrift trust to protect EUBIng tokens against creditors and lawsuits.
//NOTE: DO NOT USE!
pragma solidity ^0.4.16;

contract TokenAPI {
	function transfer(address to, uint256 value) public returns (bool success);
	function balanceOf(address who) public view returns (uint256);
	function withdrawDividend() public;
	function refuseDividends() public;
}
contract EUBINGTrustee{
	uint256 public unlockTime;
	address public revoker;
	address public beneficiary;
	address public grantor;
	//creates a new trust fund
	constructor(uint256 unlockTime1, address beneficiary1, bool revocable, bool refuseDividends) public{
		beneficiary = beneficiary1;
		unlockTime = block.timestamp + unlockTime1;
		if(revocable){
			revoker = msg.sender;
		} else{
			revoker = 0x000000000000000000000000000000000000dEaD;
		}
		grantor = msg.sender;
		if(refuseDividends){
			//todo: replace with actual EUBIng token contract address
			TokenAPI eubing = TokenAPI(0x000000000000000000000000000000000000dEaD);
			eubing.refuseDividends();
		}
	}
	//revoke a revocable trust
	function revokeTrust() public{
		address revoker1 = revoker;
		require(msg.sender == revoker1 && block.timestamp < unlockTime);
		//todo: replace with actual EUBIng token contract address
		TokenAPI eubing = TokenAPI(0x000000000000000000000000000000000000dEaD);
		eubing.withdrawDividend();
		eubing.transfer(revoker1, eubing.balanceOf(address(this)));
		selfdestruct(revoker1);
	}
	//makes a revocable trust irrevocable
	function makeIrrevocable() public{
		require(msg.sender == revoker);
		revoker = 0x000000000000000000000000000000000000dEaD;
	}
	//the beneficiary can withdraw the trust
	function withdrawTrust() public{
		require(msg.sender == beneficiary && block.timestamp >= unlockTime);
		//todo: replace with actual EUBIng token contract address
		TokenAPI eubing = TokenAPI(0x000000000000000000000000000000000000dEaD);
		eubing.withdrawDividend();
		eubing.transfer(msg.sender, eubing.balanceOf(address(this)));
		selfdestruct(msg.sender);
	}
	function() public payable{
		
	}
}
contract EUBINGTrusteeFactory{
	function createTrust(uint256 unlockTime, address beneficiary, bool revocable, bool refuseDividends) public returns (address){
		EUBINGTrustee trustee = new EUBINGTrustee(unlockTime, beneficiary, revocable, refuseDividends);
		return address(trustee);
	}
}
