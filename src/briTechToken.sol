// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BTT is ERC20 {
    constructor() ERC20("BriTech", "BTT ") {
        // Mint initial supply to contract creator
        _mint(msg.sender, 1_000_000_000 * 10 ** 18);
    }
}