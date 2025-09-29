// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BriTechLabsPreSale} from "src/briTechPreSale.sol";
import {IERC20Mock} from "test/mock_contract/IERC20Mock.sol";
import {MockAggregator} from "test/mock_contract/chainlinkMock.sol";

contract BriTechLabsPreSaleTest is Test {
    BriTechLabsPreSale public briTechLabsPreSale;
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    uint256 amount = 10 * 10**6;
    IERC20Mock paymentToken;
    IERC20Mock contractToken;
    MockAggregator mock;
    
    uint256 endPreSale;
    uint256 preSaleCost;

    function setUp () public {
        paymentToken = new IERC20Mock("USDC coin", "USDC", 6, 1_000_000, user1);
        contractToken = new IERC20Mock("BriTech coin", "BTT", 18, 5_000_000, owner);
        mock = new MockAggregator(3_000 * 1e8, block.timestamp);

        vm.prank(user1);
        paymentToken.transfer(user2, 300 * 10**6);
        vm.stopPrank();

       preSaleCost = 0.00025 ether;

        endPreSale = block.timestamp + 10 days;

        console.log("Owner BTT balance before approve:", contractToken.balanceOf(owner));

        vm.startPrank(owner);
        briTechLabsPreSale = new BriTechLabsPreSale( address(contractToken), address(paymentToken), endPreSale, preSaleCost, address(mock), 1_000_000 * 1e18);
        
        contractToken.approve(address(briTechLabsPreSale), 1000000*1e18);

        briTechLabsPreSale.depositBTT(1000000*1e18);

        vm.stopPrank();

        console.log("Contract Deployed:", address(briTechLabsPreSale)); 
        console.log("owner balance:",  contractToken.balanceOf(address(owner)));
        console.log("Contract balance:",  contractToken.balanceOf(address(briTechLabsPreSale)));
        console.log("User1 USDC balance:", paymentToken.balanceOf(user1));

    }

    function test_getTokenCost () public view {        
        console.log("Here is the presale cost:", briTechLabsPreSale.getTokenCost());
    }

    function test_SetNewDate () public {
        vm.startPrank(owner);
        briTechLabsPreSale.extendPreSaleTime(briTechLabsPreSale.endpreSale() + 30 days);
        assertEq(briTechLabsPreSale.endpreSale(), endPreSale + 30 days);
        vm.stopPrank();
    }

    function test_SetNewDateWithInvalidAddress () public {
        vm.prank(user1);
        vm.expectRevert();
        briTechLabsPreSale.extendPreSaleTime(30 days);
    }

    function test_changeCostOfToken () public {
        vm.prank(user1);
        vm.expectRevert();
        briTechLabsPreSale.setTokenCost(1 ether);
    }

    function test_buyTokenWithEth () public {
        
        vm.deal(user1, 2 ether);
        vm.deal(user2, 2 ether);
        console.log("contract eth balance before...", briTechLabsPreSale.amountRaisedEth());

        vm.startPrank(user1);
        uint256 user1Tokens = briTechLabsPreSale.buyTokenWithEth{value: 0.2 ether}();

        console.log("user1 tokens bought...", user1Tokens);
        vm.stopPrank();

        vm.startPrank(user2);
        uint256 user2Tokens = briTechLabsPreSale.buyTokenWithEth{value: 0.2 ether}();

        console.log("user2 tokens bought...", user2Tokens);
        vm.stopPrank();

        console.log("contract eth balance after...", briTechLabsPreSale.amountRaisedEth());

        vm.assertEq(briTechLabsPreSale.amountRaisedEth(), 0.4 ether);
        vm.assertEq(contractToken.balanceOf(user1), user1Tokens);
        vm.assertEq(contractToken.balanceOf(user2), user2Tokens);
    }

    
    function test_endOfPreSale () public {
        vm.startPrank(user1);
        vm.warp(40 days);
        vm.expectRevert();
        briTechLabsPreSale.buyTokenWithEth{value: 0.2 ether}();
        vm.stopPrank();
    }

    function test_showPrice () public view {
        console.log ("price value :", briTechLabsPreSale.getPriceValue());
    }


    function test_buyTokenWithUSDC () public {
        vm.startPrank(user1);
        paymentToken.approve(address(briTechLabsPreSale), 50*10**6);
        uint256 user1token = briTechLabsPreSale.buyTokenWithUSDC(50*10**6);
        console.log("user1 tokens bought...", user1token);
        vm.stopPrank();
        vm.startPrank(user2);
        paymentToken.approve(address(briTechLabsPreSale), 50*10**6);
        uint256 user2token = briTechLabsPreSale.buyTokenWithUSDC(50*10**6);
        console.log("user2tokens bought...", user1token);
        vm.stopPrank();

        vm.assertEq(briTechLabsPreSale.USDCamountRaised(), 100*10**6);
        vm.assertEq(contractToken.balanceOf(user1), user1token);
        vm.assertEq(contractToken.balanceOf(user2), user2token);
    }

    function test_WithdrawEth() public {
        vm.deal(user2, 2 ether);
        vm.startPrank(user2);
        uint256 user2Tokens = briTechLabsPreSale.buyTokenWithEth{value: 0.2 ether}();
        vm.stopPrank();

        // balances before withdraw
        uint256 ownerBalanceBefore = address(owner).balance;
        uint256 contractBalanceBefore = address(briTechLabsPreSale).balance;

        vm.startPrank(owner);
        briTechLabsPreSale.withdrawEth();
        vm.stopPrank();

        assertEq(address(briTechLabsPreSale).balance, 0);

        uint256 ownerBalanceAfter = address(owner).balance;
        assertEq(ownerBalanceAfter, ownerBalanceBefore + contractBalanceBefore);
    }

    
    function test_WithdrawUsdc () public {
        vm.startPrank(user1);
        paymentToken.approve(address(briTechLabsPreSale), 50*10**6);
        uint256 user1token = briTechLabsPreSale.buyTokenWithUSDC(50*10**6);
        vm.stopPrank();
        vm.startPrank(owner);
        briTechLabsPreSale.withdrawUSDC();
        vm.assertEq(paymentToken.balanceOf(address(owner)), 50*10**6);
    }
}