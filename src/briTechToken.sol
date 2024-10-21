// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PMT is ERC20 {
    constructor() ERC20("PERMIT", "PMT") {
        // Mint initial supply to contract creator
        _mint(msg.sender, 1_000_000_000 * 10 ** 18);
    }
}