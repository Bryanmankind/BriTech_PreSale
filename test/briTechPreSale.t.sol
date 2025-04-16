// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {StarterPreSale} from "src/briTechPreSale.sol";
import {IERC20Mock} from "test/mock_contract/IERC20Mock.sol";
import {MockAggregator} from "test/mock_contract/chainlinkMock.sol";

contract StarterPreSaleTest is Test {
    StarterPreSale public starterPreSale;
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
        paymentToken = new IERC20Mock("USDC coin", "USDC", 6, 1_000_000, owner);
        contractToken = new IERC20Mock("BriTech coin", "BTT", 18, 5_000_000, owner);
        mock = new MockAggregator(10_000_000_000, block.timestamp);

       preSaleCost = 0.0025 ether;

        endPreSale = block.timestamp + 20 days;

        console.log("Owner BTT balance before approve:", contractToken.balanceOf(owner));


        vm.startPrank(owner);
        starterPreSale = new StarterPreSale( address(contractToken), address(paymentToken), endPreSale, preSaleCost, address(mock));
        
        contractToken.approve(address(starterPreSale), 100_000 * 1e18);

        starterPreSale.depositBTT(100_000 * 1e18);

        vm.stopPrank();

        console.log("Contract Deployed:", address(starterPreSale)); 
        console.log("owner balance:",  contractToken.balanceOf(address(owner)));
        console.log("Contract balance:",  contractToken.balanceOf(address(starterPreSale)));
        console.log("User1 USDC balance:", paymentToken.balanceOf(user1));

    }

    function test_getTokenCost () public view {        
        console.log("Here is the presale cost:", starterPreSale.getTokenCost());
    }

    function test_SetNewDate () public {
        vm.startPrank(owner);
        console.log("old date:.....", starterPreSale.endpreSale());
        starterPreSale.extendPreSaleTime(30 days);
        console.log("New date:.....", starterPreSale.endpreSale());
        vm.stopPrank();
    }

    function test_SetNewDateWithInvalidAddress () public {
        vm.prank(user1);
        vm.expectRevert();
        starterPreSale.extendPreSaleTime(30 days);
    }

    function test_changeCostOfToken () public {
        vm.prank(user1);
        vm.expectRevert();
        starterPreSale.setTokenCost(1 ether);
    }

    function test_buyTokenWithEth () public {
        
        vm.deal(user1, 2 ether);
        console.log("contract eth balance before...", starterPreSale.amountRaisedEth());

        vm.startPrank(user1);
        starterPreSale.buyTokenWithEth{value: 0.2 ether}();

        console.log("contract eth balance after...", starterPreSale.amountRaisedEth());

        vm.stopPrank();

        vm.assertEq(starterPreSale.amountRaisedEth(), 0.2 ether );
    }

    function test_endOfPreSale () public {
        vm.startPrank(user1);
        vm.warp(40 days);
        vm.expectRevert();
        starterPreSale.buyTokenWithEth{value: 0.2 ether}();
        vm.stopPrank();
    }

    function test_buyTokenWithUssdc () public {
        vm.startPrank(user1);
        
        console.log("contract balance of usdc before...", starterPreSale.USDCamountRaised());

        paymentToken.approve(address(starterPreSale), 7*10**6);

        starterPreSale.buyTokenWithUSDC(7*10**6);

        console.log("contract balance of usdc after...", starterPreSale.USDCamountRaised());

        vm.stopPrank();

        vm.assertEq(starterPreSale.USDCamountRaised(), 7*10**6);
    }

    function test_WithdrawEth () public {
        vm.prank(owner);
        starterPreSale.withdrawEth();
        uint256 finalContractEthBalance = starterPreSale.amountRaisedEth();
        vm.assertEq(finalContractEthBalance, 0);
    }

    function test_WithDrawUssdc () public {
        vm.prank(owner);
        starterPreSale.withdrawUSDC();
        uint256 finalContractUSDCBalance = starterPreSale.USDCamountRaised();
        vm.assertEq(finalContractUSDCBalance, 0);
    }
}