// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Mock ERC20 implementation
contract IERC20Mock {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public _allowance;


    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address receiver
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * (10**_decimals);
        balances[receiver] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowance[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        balances[sender] -= amount;
        _allowance[sender][msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }
}