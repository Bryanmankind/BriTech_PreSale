// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {BriTechLabsPreSale} from "./briTechPreSale.sol";
import {IERC20Mock} from "test/mock_contract/IERC20Mock.sol";
import {MockAggregator} from "test/mock_contract/chainlinkMock.sol";

contract TestPreSale {
    BriTechLabsPreSale public presale;
    IERC20Mock public paymentToken;
    IERC20Mock public contractToken;
    MockAggregator public priceFeed;

    address user1 = address(0x1);
    address user2 = address(0x2);

    constructor() {
        // deploy mocks
        paymentToken = new IERC20Mock("USDC coin", "USDC", 6, 1_000_000, user1);
        contractToken = new IERC20Mock("Contract Token", "CTK", 18, 1_000_000, user1);
        priceFeed = new MockAggregator(8, 2000e8); // example price feed: 2000 USD

        // deploy presale with mocks
        presale = new BriTechLabsPreSale(
            address(contractToken),
            address(paymentToken),
            block.timestamp + 30 days,
            1 ether,
            address(priceFeed),
            1_000_000 ether
        );
    }

    // Property: No user can buy more than max allowed tokens
    function echidna_noUserExceedsMaxPurchase() public view returns (bool) {
        return presale.userPurchasedTokens(msg.sender) 
            <= presale.maxAmountOfTokensPerUser();
    }
}
