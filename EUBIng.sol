pragma solidity ^0.4.16;
//3rd candidate for deployment - up for community reviews

contract Token {
	//fill interface with fake functions to trick the linter
	function totalSupply()  public view returns (uint256 supply);

	function balanceOf(address _owner) public view returns (uint256 balance);

	function transfer(address _to, uint256 _value) public returns (bool success);

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

	function approve(address _spender, uint256 _value) public returns (bool success);

	function allowance(address _owner, address _spender) public view returns (uint256 remaining);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
}

contract IERC223Recipient { 
	function tokenFallback(address _from, uint256 _value, bytes memory _data) public;
}
contract DividendsPayingToken is Token{
	//SafeMath
	//SafeMath: add two numbers
	function safeAdd(uint256 a, uint256 b) private pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	//SafeMath: subtract two numbers
	function safeSub(uint256 a, uint256 b) private pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}
	//SafeMath: multiply two numbers
	function safeMul(uint256 a, uint256 b) private pure returns (uint256) {
		if (a == 0) {
			return 0;
		} else{
			uint256 c = a * b;
			require(c / a == b, "SafeMath: multiplication overflow");
			return c;
		}
	}
	//SafeMath: divide two numbers
	function safeDiv(uint256 a, uint256 b) private pure returns (uint256) {
		if(b == 0){
			require(false, "SafeMath: division overflow");
		} else{
			return a / b;
		}
	}
	//SafeMath: add two numbers
	function safeAdd128(uint128 a, uint128 b) private pure returns (uint128) {
		uint128 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	//SafeMath: subtract two numbers
	function safeSub128(uint128 a, uint128 b) private pure returns (uint128) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}
	//SafeMath: multiply two numbers
	function safeMul128(uint128 a, uint128 b) private pure returns (uint128) {
		if (a == 0) {
			return 0;
		} else{
			uint128 c = a * b;
			require(c / a == b, "SafeMath: multiplication overflow");
			return c;
		}
	}
	//SafeMath: divide two numbers
	function safeDiv128(uint128 a, uint128 b) private pure returns (uint128) {
		if(b == 0){
			require(false, "SafeMath: division overflow");
		} else{
			return a / b;
		}
	}
	//SafeMath: add two numbers
	function safeAdd(int256 a, int256 b) private pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a), "SafeMath: addition overflow");

		return c;
	}
	//SafeMath: subtract two numbers
	function safeSub(int256 a, int256 b) private pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b <= 0 && c >= a), "SafeMath: subtraction overflow");

		return c;
	}
	//SafeCast: converts an signed int256 into a unsigned uint256.
	function toUint256(int256 value) private pure returns (uint256) {
		if(value < 0){
			require(false, "SafeCast: value must be positive");
		} else{
			return uint256(value);
		}
	}
	//SafeCast: converts an unsigned uint256 into a signed int256.
	function toInt256(uint256 value) private pure returns (int256) {
		if(value >= 57896044618658097711785492504343953926634992332820282019728792003956564819968){
			require(false, "SafeCast: value doesn't fit in an int256");
		} else{
			return int256(value);
		}
	}
	//SafeCast: converts an signed uint256 into a unsigned uint128, and keep it under the supply limit.
	function bc128(uint256 value) private pure returns (uint128) {
		if(value >= 10000000 szabo){
			require(false, "SafeCast: supply overflow");
		} else{
			return uint128(value);
		}
	}
	//Events
	event Burn(address holder, uint256 value);
	event DividendsDistributed(address holder, uint256 value);
	event DividendWithdrawn(address holder, uint256 value);
	function totalBurned() public view returns (uint256){
		return safeSub128(10000000 szabo, _totalSupply);
	}
	function isContract(address account) public view returns (bool) {
		// This method relies in extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly { size := extcodesize(account) }
		return size != 0;
	}
	function transfer(address to, uint256 value) public returns (bool success){
		bytes memory empty = hex"00000000";
		return transferImpl(msg.sender, to, value, empty);
	}
	//EUBIApps: take out a zero-interest flash loan from any wallets you want
	function flashLoan(address creditor, bytes memory data) public returns (bool success){
		if(creditor == creator){
			return false;
		} else if(isContract(msg.sender)) {
			uint256 credbal = balances[creditor];
			if(transferImpl(creditor, msg.sender, credbal, data)){
				if(balances[creditor] < credbal){
					revert("FlashLoan: debt default");
					return false;
				}
				else{
					return true;
				}
			} else{
				return false;
			}
		} else{
			return false;
		}
	}
	//EUBIApps: take out a zero-interest flash loan from any wallets you want
	function flashLoan(address creditor) public returns (bool success){
		bytes memory empty = hex"00000000";
		return flashLoan(creditor, empty);
	}
	//transfers tokens between your wallet and another wallet
	function transfer(address _to, uint256 _value, bytes memory data) public returns (bool success) {
		return transferImpl(msg.sender, _to, _value, data);
	}
	bool public burnReturnedTokens;
	//ERC223 transfers
	function transferImpl(address _from, address _to, uint256 _value, bytes memory data) internal returns (bool success) {
		//Relaxed SafeSend protection
		require(SafeSendMutex, "SafeSend: Mutex locked");
		uint128 sender_balance = balances[_from];
		uint128 reciever_balance = balances[_to];
		uint128 locked1 = 0;
		uint128 value128 = bc128(_value);
		uint128 old2new = 0;
		//Tokens sent back to contract are burned
		if(_to == address(this)){
			if(burnReturnedTokens){
				_to = 0x000000000000000000000000000000000000dEaD;
			}
		}
		//Burning tokens is exempt from token unlock period.
		if(_from == creator && _to != 0x000000000000000000000000000000000000dEaD){
			locked1 = bc128(locked());
		}
		uint128 effective_value = locked1 + value128;

		require(effective_value >= locked1, "SafeMath: addition overflow");
		if(effective_value > sender_balance){
			//if we have insufficent balance to cover the transaction, convert from old EUBI if possible.
			old2new = bc128(availableOldEUBI(_from));
			sender_balance = sender_balance + old2new;
			require(sender_balance >= old2new, "SafeMath: addition overflow");
			if(effective_value > sender_balance){
				return false;
			} else{
				oldEUBI.transferFrom(_from, address(this), old2new);
			}
		}
		if (sender_balance >= effective_value) {
			//Send tokens to 0x000000000000000000000000000000000000dead to burn them
			if(_to == 0x000000000000000000000000000000000000dEaD){
				balances[_from] = sender_balance - value128;
				magnifiedDividendCorrections[_from] = safeAdd(magnifiedDividendCorrections[_from], toInt256(safeMul(magnifiedDividendPerShare, value128)));
				old2new = _totalSupply;
				require(value128 <= old2new, "SafeMath: subtraction overflow");
				old2new -= value128;
				_totalSupply = old2new;
				emit Burn(_from, _value);
			} else{
				require(value128 <= sender_balance, "SafeMath: subtraction overflow");
				//gas optimization
				if(value128 == sender_balance){
					delete balances[_from];
				} else{
					balances[_from] = sender_balance - value128;
				}
				effective_value = reciever_balance + value128;
				require(effective_value <= 10000000 szabo, "SafeCast: supply overflow");
				require(effective_value >= reciever_balance, "SafeMath: addition overflow");
				balances[_to] = effective_value;
				if(isContract(_to)){
					IERC223Recipient receiver = IERC223Recipient(_to);
					receiver.tokenFallback(msg.sender, _value, data);
				}
				updateDividends(_from, _to, _value, toInt256(safeMul(magnifiedDividendPerShare, value128)));
			}
			emit Transfer(_from, _to, _value);
			return true;
		} else {
			return false;
		}
	}
	function updateDividends(address sender, address receiver, uint256 value, int256 _magCorrection) private {
		bool sender_refused_dividends = refusedDividends[sender];
		bool reciever_refused_dividends = refusedDividends[receiver];
		if(sender_refused_dividends == reciever_refused_dividends){
			if(!sender_refused_dividends){
				magnifiedDividendCorrections[receiver] = safeSub(magnifiedDividendCorrections[receiver], _magCorrection);
				magnifiedDividendCorrections[sender] = safeAdd(magnifiedDividendCorrections[sender], _magCorrection);
			}
		} else{
			if(sender_refused_dividends){
				dividendsRefusingSupply = safeSub128(dividendsRefusingSupply, uint128(value));
				magnifiedDividendCorrections[receiver] = safeSub(magnifiedDividendCorrections[receiver], _magCorrection);
			} else{
				dividendsRefusingSupply = safeAdd128(dividendsRefusingSupply, uint128(value));
				magnifiedDividendCorrections[sender] = safeAdd(magnifiedDividendCorrections[sender], _magCorrection);
			}
		}
	}
	//transfers tokens from a wallet you are approved to send tokens from
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		bytes memory empty = hex"00000000";
		uint128 allowed_sender = allowed[_from][msg.sender];
		if(allowed_sender >= _value){
			if(transferImpl(_from, _to, _value, empty)){
				uint128 safecheck = allowed_sender - uint128(_value);
				require(safecheck <= allowed_sender, "SafeMath: subtraction overflow");
				allowed[_from][msg.sender] = safecheck;
				return true;
			}
		}
		return false;
	}
	function availableOldEUBI(address _owner) public view returns (uint256 balance){
		uint256 aoe = oldEUBI.allowance(_owner, address(this));
		uint256 temp3 = oldEUBI.balanceOf(_owner);
		if(aoe < temp3){
			aoe = temp3;
		}
		temp3 = balances[address(this)];
		if(aoe > temp3){
			return temp3;
		}
		else{
			return aoe;
		}
	}
	//gets the balance of a wallet
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return safeAdd(balances[_owner], availableOldEUBI(_owner));
	}
	//approves someone to send your tokens from your wallet
	function approve(address _spender, uint256 _value) public returns (bool success) {
		if(_value > 340282366920938463463374607431768211456){
			_value = 340282366920938463463374607431768211456;
		}
		allowed[msg.sender][_spender] = uint128(_value);
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	//check your remaining allowance for sending tokens from someone else's wallet
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		  return allowed[_owner][_spender];
	}
	//data storage
	mapping (address => uint128) balances;
	mapping (address => mapping (address => uint128)) allowed;
	uint128 internal _totalSupply;
	function totalSupply() public view returns (uint256){
		return _totalSupply;
	}

	//Dividends distributer begins here
	
	//more data storage
	uint256 internal magnifiedDividendPerShare;
	mapping(address => int256) internal magnifiedDividendCorrections;
	mapping(address => uint256) internal withdrawnDividends;
	mapping(address => bool) internal refusedDividends;
	function refuseDividends() public{
		refusedDividends[msg.sender] = true;
		dividendsRefusingSupply = safeAdd128(dividendsRefusingSupply, balances[msg.sender]);
	}
	uint128 public dividendsRefusingSupply;
	bool public SafeSendMutex;
	//handles payments to contract
	function() external payable {
		//Full SafeSend protection
		require(SafeSendMutex, "SafeSend: Mutex locked");
		SafeSendMutex = false;
		uint128 trueSupply = safeSub128(_totalSupply, dividendsRefusingSupply);
		require(trueSupply != 0, "ERC1726: zero supply");
		if (msg.value != 0) {
			magnifiedDividendPerShare = safeAdd(magnifiedDividendPerShare, safeMul(msg.value, 340282366920938463463374607431768211456) / trueSupply);
			emit DividendsDistributed(msg.sender, msg.value);
		}
		SafeSendMutex = true;
	}
	//withdraw dividends
	function withdrawDividend() public {
		if(!refusedDividends[msg.sender]){
			//Full SafeSend protection
			require(SafeSendMutex, "SafeSend: Mutex locked");
			SafeSendMutex = false;
			uint256 _withdrawableDividend = withdrawableDividendOf(msg.sender);
			if (_withdrawableDividend != 0) {
				//Insufficient balance protection
				uint256 bal = address(this).balance;
				if(_withdrawableDividend > bal){
					_withdrawableDividend = bal;
				}
				require(msg.sender.call.value(_withdrawableDividend)(), "SafeSend: Can't send ether");
				withdrawnDividends[msg.sender] = safeAdd(withdrawnDividends[msg.sender], _withdrawableDividend);
				emit DividendWithdrawn(msg.sender, _withdrawableDividend);
			}
			SafeSendMutex = true;
		}
	}
	//check how much unpaid dividends a shareholder have
	function dividendOf(address _owner) public view returns(uint256) {
		return withdrawableDividendOf(_owner);
	}
	//check how much unpaid dividends a shareholder have
	function withdrawableDividendOf(address _owner) public view returns(uint256) {
		return safeSub(accumulativeDividendOf(_owner), withdrawnDividends[_owner]);
	}
	//check how much dividends a shareholder have withdrawn
	function withdrawnDividendOf(address _owner) public view returns(uint256) {
		return withdrawnDividends[_owner];
	}
	//check how much dividends a shareholder have earned
	function accumulativeDividendOf(address _owner) public view returns(uint256) {
		return safeDiv(toUint256(safeAdd(toInt256(safeMul(magnifiedDividendPerShare, balances[_owner])), magnifiedDividendCorrections[_owner])), 340282366920938463463374607431768211456);
	}
	
	//BEGIN token release period implementation
	address public creator;
	uint128 public initialUnlock;
	uint128 public initialLocked;
	uint128 public creationTime;
	uint128 public fullUnlockTime;
	function unlocked() public view returns (uint128){
		//Rouge miner protection
		require(block.timestamp > creationTime, "EUBIUnlocker: bad timestamp!");
		if(block.timestamp > fullUnlockTime){
			return 10000000 szabo;
		} else{
			return safeAdd128(safeDiv128(safeMul128(safeSub128(uint128(block.timestamp), creationTime), initialLocked), 94608000), initialUnlock);
		}
	}
	function locked() public view returns (uint128){
		return safeSub128(10000000 szabo, unlocked());
	}
	
	Token public oldEUBI;
}

contract EUBIDEFI is IERC223Recipient{
	//SafeMath
	//SafeMath: subtract two numbers
	function safeSub(uint256 a, uint256 b) private pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}
	//SafeMath: subtract two numbers
	function safeSub128(uint128 a, uint128 b) private pure returns (uint128) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}
	//SafeMath: multiply two numbers
	function safeMul(uint256 a, uint256 b) private pure returns (uint256) {
		if (a == 0) {
			return 0;
		} else{
			uint256 c = a * b;
			require(c / a == b, "SafeMath: multiplication overflow");
			return c;
		}
	}
	//SafeMath: divide two numbers
	function safeDiv(uint256 a, uint256 b) private pure returns (uint256) {
		if(b == 0){
			require(false, "SafeMath: division overflow");
		} else{
			return a / b;
		}
	}
	//SafeMath: add two numbers
	function safeAdd128(uint128 a, uint128 b) private pure returns (uint128) {
		uint128 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	//SafeMath: add two numbers
	function safeAdd(uint256 a, uint256 b) private pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	//Safe ether sending
	function FlushWallet(uint256 txvalue) internal{
		//Full SafeSend protection + dividends burning protection
		require(SafeSendMutex, "SafeSend: Mutex locked");
		SafeSendMutex = false;
		require(creator.call.value(txvalue)(), "SafeSend: Can't send ether");
		SafeSendMutex = true;
	}
	constructor(address dfx1, address msgsender) public{
		//DO NOT MODIFY
		creator = msgsender;
		//DO NOT MODIFY
		SafeSendMutex = true;
		//DO NOT MODIFY
		mystate = block.number * 340282366920938463463374607431768211456;
		//DO NOT MODIFY
		eubi = dfx1;
	}
	bool internal SafeSendMutex;
	//uint128 public soldTokens;
	//uint128 public creationBlock;
	uint256 private mystate;
	address public creator;
	address public eubi;
	//handles payments to contracts
	function recieveDeposit() payable public{
		uint256 txvalue = msg.value;
		require(txvalue < 340282366920938463463374607431768211456, "SafeCast: value doesn\'t fit in 128 bits");
		uint256 loadmystate = mystate;
		uint128 index = safeSub128(uint128(block.number), uint128(loadmystate / 340282366920938463463374607431768211456));
		uint128 sellable = (342465753424657532 * index) / 30;
		uint128 soldTokens = uint128(loadmystate % 340282366920938463463374607431768211456);
		require(soldTokens <= sellable, "SafeMath: subtraction overflow");
		sellable = sellable - soldTokens;
		//price algo for dutch auction
		uint128 price = (250000000 * (index % 30)) / 29;
		require(price <= 250000000, "SafeMath: subtraction overflow");
		price = 500000000 - price;
		price = uint128(txvalue / price);
		mystate = safeAdd(loadmystate, price);
		require(price < sellable, "EUBIDEFI: rate of sale limit exceeded");
		FlushWallet(txvalue);
		Token dfx = Token(eubi);
		require(dfx.transfer(msg.sender, price), "EUBIDEFI: out of stock");
	}
	function() public payable {
		if(SafeSendMutex){
			recieveDeposit();
		}
	}
	function tokenFallback(address _from, uint256 _value, bytes memory _data) public{
		require(msg.sender == eubi, "Only EUBI tokens are accepted!");
		emit IPOTopup(_from, _value, _data);
	}
	event IPOTopup(address _from, uint256 _value, bytes _data);
}

//EUBIng core contract
contract EUBING is DividendsPayingToken {
	//SafeMath
	//SafeMath: add two numbers
	function safeAdd(uint256 a, uint256 b) private pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	//SafeMath: add two numbers
	function safeAdd128(uint128 a, uint128 b) private pure returns (uint128) {
		uint128 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	//SafeMath: subtract two numbers
	function safeSub(uint256 a, uint256 b) private pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}
	//SafeMath: subtract two numbers
	function safeSub(int256 a, int256 b) private pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b <= 0 && c >= a), "SafeMath: subtraction overflow");

		return c;
	}
	//SafeMath: multiply two numbers
	function safeMul(uint256 a, uint256 b) private pure returns (uint256) {
		if (a == 0) {
			return 0;
		} else{
			uint256 c = a * b;
			require(c / a == b, "SafeMath: multiplication overflow");
			return c;
		}
	}
	//SafeMath: subtract two numbers
	function safeSub128(uint128 a, uint128 b) private pure returns (uint128) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}
	//SafeCast: converts an unsigned uint256 into a signed int256.
	function toInt256(uint256 value) private pure returns (int256) {
		if(value > 57896044618658097711785492504343953926634992332820282019728792003956564819967){
			require(false, "SafeCast: value doesn't fit in an int256");
		} else{
			return int256(value);
		}
	}
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version = 'H1.0';
	address public EUBIDEFIAddr;
	bool public allowConstruction = true;
	//constructor
	constructor() public {
		if(allowConstruction){
			//Old EUBI token
			oldEUBI = Token(0x8AFA1b7a8534D519CB04F4075D3189DF8a6738C1);
			//DO NOT MODIFY
			SafeSendMutex = true;
			//Set up creator's wallet
			_totalSupply = 10000000 szabo;
			magnifiedDividendCorrections[msg.sender] = safeSub(0, toInt256(safeMul(magnifiedDividendPerShare, 10000000 szabo)));
			balances[msg.sender] = 10000000 szabo;
			//Token configuration
			name = "EUB Insurance";
			decimals = 12;
			symbol = "EUBI";
			creator = msg.sender;
			//Set up token release period
			//NOTE: we need to initially unlock an additional 2 million EUBI for Defi IPO + migration
			initialUnlock = 5370091 szabo;
			initialLocked = safeSub128(10000000 szabo, initialUnlock);
			//ROUGE MINER PROTECTION: Both Geth and Parity reject blocks with timestamp more than 15 seconds in the future
			creationTime = safeSub128(uint128(block.timestamp), 20);
			//It would take 94608000 seconds (3 years) for all the tokens to be unlocked.
			fullUnlockTime = safeAdd128(creationTime, 94608000);
			bytes memory empty = hex"00000000";
			//DO NOT MODIFY
			burnReturnedTokens = false;
			//Max token migration: 1 million EUBI
			address myaddr = address(this);
			//Sell tokens via EUBIDEFI
			address EUBIDEFIAddr1 = address(new EUBIDEFI(myaddr, msg.sender));
			EUBIDEFIAddr = EUBIDEFIAddr1;
			//Fix dividends burning bug
			dividendsRefusingSupply = 0;
			refusedDividends[myaddr] = true;
			refusedDividends[EUBIDEFIAddr1] = true;
			transferImpl(msg.sender, EUBIDEFIAddr1, 1000000 szabo, empty);
			transferImpl(msg.sender, myaddr, 1000000 szabo, empty);
			//DO NOT MODIFY
			allowConstruction = false;
			//DO NOT MODIFY
			burnReturnedTokens = true;
		} else{
			require(false, "EUBING: construction prohibited");
		}
	}
	//approves and then calls the receiving contract
	function approveAndCall(address _spender, uint256 _value) public returns (bool success) {
		bytes memory _extraData = hex"00000000";
		if(_value > 340282366920938463463374607431768211455){
			_value = 340282366920938463463374607431768211455;
		}
		allowed[msg.sender][_spender] = uint128(_value);
		emit Approval(msg.sender, _spender, _value);
		if(_spender.call(0x8f4ffcb1, msg.sender, _value, this, _extraData)){
			return true;
		} else{
			revert("ERC20: receiveApproval(address,uint256,address,bytes) not defined in recipient");
			return false;
		}
	}
	//approves and then calls the receiving contract
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
		if(_value > 340282366920938463463374607431768211455){
			_value = 340282366920938463463374607431768211455;
		}
		allowed[msg.sender][_spender] = uint128(_value);
		emit Approval(msg.sender, _spender, _value);
		if(_spender.call(0x8f4ffcb1, msg.sender, _value, this, _extraData)){
			return true;
		} else{
			revert("ERC20: receiveApproval(address,uint256,address,bytes) not defined in recipient");
			return false;
		}
	}
}
