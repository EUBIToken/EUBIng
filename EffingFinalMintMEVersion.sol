pragma solidity =0.4.26;
contract TokenInterface{
	function transfer(address _to, uint256 _value) public returns (bool success);
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}
contract IERC223Recipient{
	function tokenFallback(address _from, uint _value, bytes memory _data) public;
}
library SignedSafeMath {
	function mul(int256 a, int256 b) internal pure returns (int256) {
		require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
		int256 c = a * b;
		require((b == 0) || (c / b == a), "SafeMath: multiplication overflow");
		return c;
	}

	function div(int256 a, int256 b) internal pure returns (int256) {
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

contract EUBIng2 {
	using SignedSafeMath for int256;
	using UnsignedSafeMath for uint256;
	mapping (address => uint256) private _balances;

	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;
	constructor () public {
		_mint(0x7a7C3dcBa4fBf456A27961c6a88335b026052C65, 90000000 szabo);
		//Token unlock period
		creationTime = block.timestamp.add(20);
		fullUnlockTime = creationTime.add(94608000);
		creator = 0x7a7C3dcBa4fBf456A27961c6a88335b026052C65;
	}

	function name() external pure returns (string memory) {
		return "EUBIng2";
	}

	function symbol() external pure returns (string memory) {
		return "EUBI";
	}

	function decimals() external pure returns (uint8) {
		return 12;
	}
	function totalSupply() public view returns (uint256){
		return _totalSupply;
	}
	event Transfer(address from, address to, uint256 amount);
	event Approval(address from, address to, uint256 amount);
	mapping(address => bool) private dividendsOptIn;
	uint256 public dividendsRecievingSupply;
	mapping(address => int256) private magnifiedDividendCorrections;
	uint256 public magnifiedDividendPerShare;
	uint256 private creationTime;
	uint256 private fullUnlockTime;
	address private creator;
	
	function canRecieveDividends(address addr) public view returns (bool){
		if(addr == msg.sender){
			return msg.sender != tx.origin || dividendsOptIn[addr];
		}
		else{
			return (!isContract(addr) || dividendsOptIn[addr]) && addr != 0x0000000000000000000000000000000000000000;
		}
	}
	
	function enableDividends() external{
		//Smart contracts are presumed to refuse dividends unless otherwise stated
		if(!canRecieveDividends(msg.sender)){
			dividendsOptIn[msg.sender] = true;
			magnifiedDividendCorrections[msg.sender] = int256(0).sub(magnifiedDividendPerShare.mul(_balances[msg.sender]).toInt256Safe());
			dividendsRecievingSupply = dividendsRecievingSupply.add(_balances[msg.sender]);
		}
	}
	function _mint(address account, uint256 amount) private {
		require(totalSupply().add(amount) <= 10000000 szabo, "ERC20Capped: cap exceeded");
		require(account != address(0), "ERC20: mint to the zero address");
		_totalSupply = _totalSupply.add(amount);
		if(canRecieveDividends(account)){
			dividendsRecievingSupply = dividendsRecievingSupply.add(amount);
			magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
		}
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}
	function DEFIPurchase() external payable{
		_mint(msg.sender, msg.value / 295000000);
		0x7a7C3dcBa4fBf456A27961c6a88335b026052C65.transfer(msg.value);
	}
	function _burn(address account, uint256 amount) private {
		require(account != address(0), "ERC20: burn from the zero address");
		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
		_balances[account] = accountBalance - amount;
		_totalSupply = _totalSupply.sub(amount);
		if(canRecieveDividends(account)){
			dividendsRecievingSupply = dividendsRecievingSupply.sub(amount);
			magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
		}
		emit Transfer(account, address(0), amount);
	}
	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	function isContract(address account) internal view returns (bool) {
		// This method relies in extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly { size := extcodesize(account) }
		return size > 0;
	}
	function unlocked() public view returns (uint256){
		//Rouge miner protection
		require(block.timestamp > creationTime, "EUBIUnlocker: bad timestamp");
		if(block.timestamp > fullUnlockTime){
			return 10000000 szabo;
		} else{
			return block.timestamp.sub(creationTime).mul(5629909 szabo).div(94608000).add(3370091 szabo);
		}
	}
	function locked() public view returns (uint256){
		uint256 supply = 10000000 szabo;
		return supply.sub(unlocked());
	}
	function _transfer(address sender, address recipient, uint256 amount) private {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		senderBalance -= amount;
		if(sender == creator){
			require(senderBalance >= locked(), "EUBIUnlocker: not unlocked");
		}
		_balances[sender] = senderBalance;
		_balances[recipient] = _balances[recipient].add(amount);
		uint256 dividendsRecievingSupply1 = dividendsRecievingSupply;
		int256 _magCorrection = magnifiedDividendPerShare.mul(amount).toInt256Safe();
		if(canRecieveDividends(msg.sender)){
			dividendsRecievingSupply1 = dividendsRecievingSupply1.sub(amount);
			magnifiedDividendCorrections[msg.sender] = magnifiedDividendCorrections[msg.sender].add(_magCorrection);
		}
		if(canRecieveDividends(recipient)){
			dividendsRecievingSupply1 = dividendsRecievingSupply1.add(amount);
			magnifiedDividendCorrections[recipient] = magnifiedDividendCorrections[recipient].sub(_magCorrection);
		}
		dividendsRecievingSupply = dividendsRecievingSupply1;
		if(isContract(recipient)){
			IERC223Recipient receiver = IERC223Recipient(recipient);
			bytes memory empty = hex"00000000";
			receiver.tokenFallback(msg.sender, amount, empty);
		}
		emit Transfer(sender, recipient, amount);
	}

	function balanceOf(address account) external view returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) external returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) external view returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][msg.sender];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		_approve(sender, msg.sender, currentAllowance - amount);

		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		uint256 currentAllowance = _allowances[msg.sender][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		_approve(msg.sender, spender, currentAllowance - subtractedValue);
		return true;
	}
	
	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
	}

	function burnFrom(address account, uint256 amount) external {
		uint256 currentAllowance = _allowances[account][msg.sender];
		require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
		_approve(account, msg.sender, currentAllowance - amount);
		_burn(account, amount);
	}
	function transfer(address recipient, uint256 amount, bytes memory data) public {
		require(msg.sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		uint256 senderBalance = _balances[msg.sender];
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		senderBalance -= amount;
		if(msg.sender == creator){
			require(senderBalance >= locked(), "EUBIUnlocker: not unlocked");
		}
		_balances[msg.sender] = senderBalance;
		_balances[recipient] = _balances[recipient].add(amount);
		uint256 dividendsRecievingSupply1 = dividendsRecievingSupply;
		int256 _magCorrection = magnifiedDividendPerShare.mul(amount).toInt256Safe();
		if(canRecieveDividends(msg.sender)){
			dividendsRecievingSupply1 = dividendsRecievingSupply1.sub(amount);
			magnifiedDividendCorrections[msg.sender] = magnifiedDividendCorrections[msg.sender].add(_magCorrection);
		}
		if(canRecieveDividends(recipient)){
			dividendsRecievingSupply1 = dividendsRecievingSupply1.add(amount);
			magnifiedDividendCorrections[recipient] = magnifiedDividendCorrections[recipient].sub(_magCorrection);
		}
		dividendsRecievingSupply = dividendsRecievingSupply1;
		if(isContract(recipient)){
			IERC223Recipient receiver = IERC223Recipient(recipient);
			receiver.tokenFallback(msg.sender, amount, data);
		}
		emit Transfer(msg.sender, recipient, amount);
	}
	mapping(address => uint256) internal withdrawnDividends;
	function accumulativeDividendOf(address _owner) public view returns(uint256) {
		return magnifiedDividendPerShare.mul(_balances[_owner]).toInt256Safe().add(magnifiedDividendCorrections[_owner]).toUint256Safe() / 340282366920938463463374607431768211456;
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
	event DividendWithdrawn(address a, uint256 b);
	function withdrawDividend() external {
	uint256 _withdrawableDividend = withdrawableDividendOf(msg.sender);
		if (_withdrawableDividend > 0 && canRecieveDividends(msg.sender)) {
			withdrawnDividends[msg.sender] = withdrawnDividends[msg.sender].add(_withdrawableDividend);
			require(msg.sender.call.value(_withdrawableDividend)(), "EUBIng2: Can't send dividends");
			emit DividendWithdrawn(msg.sender, _withdrawableDividend);
		}
	}
	
	function withdrawDividendFor(address addr) external {
		uint256 _withdrawableDividend = withdrawableDividendOf(addr);
		if (_withdrawableDividend > 0) {
			withdrawnDividends[addr] = withdrawnDividends[addr].add(_withdrawableDividend);
			addr.transfer(_withdrawableDividend);
			emit DividendWithdrawn(addr, _withdrawableDividend);
		}
	}
	event DividendsDistributed(address from, uint256 amount);

	function distributeDividends() external payable{
		if(msg.value != 0){
			//Flash burning prevents dividends from being kicked back to sender
			uint256 balanceBeforeDistribution = _balances[msg.sender];
			_burn(msg.sender, balanceBeforeDistribution);
			magnifiedDividendPerShare = magnifiedDividendPerShare.add(msg.value.mul(340282366920938463463374607431768211456).div(dividendsRecievingSupply));
			_mint(msg.sender, balanceBeforeDistribution);
			emit DividendsDistributed(msg.sender, msg.value);
		}
	}
}
