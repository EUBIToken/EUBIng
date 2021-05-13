pragma solidity =0.5.16;
library SignedSafeMath {
	function mul(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when multiplying INT256_MIN with -1
		// https://github.com/RequestNetwork/requestNetwork/issues/43
		require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
		int256 c = a * b;
		require((b == 0) || (c / b == a), "SafeMath: multiplication overflow");
		return c;
	}

	function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing INT256_MIN by -1
		// https://github.com/RequestNetwork/requestNetwork/issues/43
		require(!(a == - 2**255 && b == -1) && (b > 0), "SafeMath: division overflow");
		return a / b;
	}

	function sub(int256 a, int256 b) internal pure returns (int256) {
		require((b >= 0 && a - b <= a) || (b < 0 && a - b > a), "SafeMath: subtraction overflow");
		return a - b;
	}

	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a), "SafeMath: addition overflow");
		return c;
	}

	function toUint256Safe(int256 a) internal pure returns (uint256) {
		require(a >= 0, "SafeCast: value must be positive");
		return uint256(a);
	}
}
library UnsignedSafeMath {
	function toInt256Safe(uint256 a) internal pure returns (int256) {
		int256 b = int256(a);
		require(b >= 0, "SafeCast: value doesn't fit in an int256");
		return b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		} else{
			uint256 c = a * b;
			require(c / a == b, "SafeMath: multiplication overflow");
			return c;
		}
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		if(b == 0){
			require(false, "SafeMath: division overflow");
		} else{
			return a / b;
		}
	}
}
//used to pay dividends in USDC
contract TokenInterface{
	function balanceOf(address _owner) public view returns (uint256 balance);

	function transfer(address _to, uint256 _value) public returns (bool success);
}
contract UniswapV2EUBING {
	using UnsignedSafeMath for uint256;
	using SignedSafeMath for int256;

	string public constant name = 'EUB Insurance';
	string public constant symbol = 'EUBI';
	uint8 public constant decimals = 12;
	uint  public totalSupply;
	uint256 private creationTime;
	uint256 private fullUnlockTime;
	address private creator;
	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;

	bytes32 public DOMAIN_SEPARATOR;
	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	mapping(address => uint) public nonces;

	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);

	constructor() public {
		uint chainId;
		assembly {
			chainId := chainid
		}
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
				keccak256(bytes(name)),
				keccak256(bytes('1')),
				chainId,
				address(this)
			)
		);
		_mint(msg.sender, 10000000 szabo);
		//Token unlock period
		creationTime = block.timestamp.add(20);
		fullUnlockTime = creationTime.sub(94608000);
		creator = msg.sender;
	}

	function _mint(address to, uint value) internal {
		TokenInterface usdc = TokenInterface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
		uint256 magnifiedDividendPerShare = usdc.balanceOf(address(this)).add(totalWithdrawnDividends).mul(340282366920938463463374607431768211456);
		magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
		totalSupply = totalSupply.add(value);
		balanceOf[to] = balanceOf[to].add(value);
		emit Transfer(address(0), to, value);
	}

	function _burn(address from, uint value) internal {
		balanceOf[from] = balanceOf[from].sub(value);
		totalSupply = totalSupply.sub(value);
		emit Transfer(from, address(0), value);
	}

	function _approve(address owner, address spender, uint value) private {
		allowance[owner][spender] = value;
		emit Approval(owner, spender, value);
	}
	
	function unlocked() public view returns (uint256){
		//Rouge miner protection
		require(block.timestamp > creationTime, "EUBIUnlocker: bad timestamp");
		if(block.timestamp > fullUnlockTime){
			return 10000000 szabo;
		} else{
			return block.timestamp.sub(creationTime).mul(6629909 szabo).div(94608000).add(3370091 szabo);
		}
	}
	function locked() public view returns (uint256){
		uint256 supply = 10000000 szabo;
		return supply.sub(unlocked());
	}

	function _transfer(address from, address to, uint value) private {
		uint256 balanceAfter = balanceOf[from].sub(value);
		if(from == creator){
			require(balanceAfter >= locked(), "EUBIUnlocker: not unlocked");
		}
		TokenInterface usdc = TokenInterface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
		uint256 magnifiedDividendPerShare = usdc.balanceOf(address(this)).add(totalWithdrawnDividends).mul(340282366920938463463374607431768211456);
		int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
		magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
		magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
		balanceOf[from] = balanceAfter;
		balanceOf[to] = balanceOf[to].add(value);
		emit Transfer(from, to, value);
	}

	function approve(address spender, uint value) external returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint value) external returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(address from, address to, uint value) external returns (bool) {
		if (allowance[from][msg.sender] != uint(-1)) {
			allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
		}
		_transfer(from, to, value);
		return true;
	}

	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
		require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR,
				keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
			)
		);
		address recoveredAddress = ecrecover(digest, v, r, s);
		require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
		_approve(owner, spender, value);
	}
	//Begin dividends distributor
	mapping(address => int256) internal magnifiedDividendCorrections;
	mapping(address => uint256) internal withdrawnDividends;
	uint256 public totalWithdrawnDividends = 0;
	function accumulativeDividendOf(address _owner) public view returns(uint256) {
		TokenInterface usdc = TokenInterface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
		uint256 magnifiedDividendPerShare = usdc.balanceOf(address(this)).add(totalWithdrawnDividends).mul(340282366920938463463374607431768211456);
		return magnifiedDividendPerShare.mul(balanceOf[_owner]).toInt256Safe().add(magnifiedDividendCorrections[_owner]).toUint256Safe() / 340282366920938463463374607431768211456;
	}
	event DividendWithdrawn(address a, uint256 b);
	function withdrawDividend() public {
	uint256 _withdrawableDividend = withdrawableDividendOf(msg.sender);
		if (_withdrawableDividend > 0) {
			totalWithdrawnDividends = totalWithdrawnDividends.add(_withdrawableDividend);
			withdrawnDividends[msg.sender] = withdrawnDividends[msg.sender].add(_withdrawableDividend);
			TokenInterface usdc = TokenInterface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
			require(usdc.transfer(msg.sender, _withdrawableDividend));
			emit DividendWithdrawn(msg.sender, _withdrawableDividend);
		}
	}

	function dividendOf(address _owner) public view returns(uint256) {
		return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
	}

	function withdrawableDividendOf(address _owner) public view returns(uint256) {
		return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
	}

	function withdrawnDividendOf(address _owner) public view returns(uint256) {
		return withdrawnDividends[_owner];
	}
	    
	function burn(uint256 amount) public returns (bool){
		_burn(msg.sender, amount);
		return true;
	}
}
