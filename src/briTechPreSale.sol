// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StarterPreSale is Ownable{

    using SafeERC20 for IERC20;

    // Error handeling
    error invalidAccount();
    error invalidPrice();
    error fundsTooLow();
    error tokensSoldOut();
    error invalidPayment();
    error preSaleIsOver();
    error tokenNotSent();
    error failedToSendMoney();
    error preSaleNotOver();
    error invalidDate();

    // payment token to contract 
    IERC20 public USDC;

    // contract native token
    IERC20 public BTT;
    
    uint256 public preSaleStartTime;
    uint256 public endpreSale;
    uint256 public soldTokens;
    uint256 public amountRaisedUSDC;
    uint256 public amountRaisedEth;

    uint256 public minimumUSDC = 2 * 10** 6; // minimum amount to get to tokens in ustd
    uint256 public minimumEth = 0.000691 ether; // minimum amount to get to tokens in eth

    uint256 public costOfToken;
    uint256 public tokenPerUSDC;
    uint256 public preSaleCost =  0.000050059 ether;
    uint256 public costAfterPresale =  0.000060000 ether;
    uint256 public preSaleCostUSDC =  6000;
    uint256 public costAfterPresaleUSDC =  1500;


    modifier checkPrice (uint256 _price) {
        if (_price == 0) {
            revert invalidPrice();
        }
        _;
    }
    
    event BuyToken (address indexed user,  uint256 indexed amount);
    event PriceUpdated(uint256 newPrice);

    constructor (address _tokenAddress, address paymentAdd, uint256 _endPreSale) Ownable(msg.sender) {
        BTT = IERC20(_tokenAddress);
        USDC = IERC20(paymentAdd);
      
        preSaleStartTime = block.timestamp;
        endpreSale = _endPreSale;
        BTT.safeIncreaseAllowance(address(this), type(uint256).max);
    }

    receive() external payable {
        buyTokenWithEth ();
    }

    function getTokenCost() external view returns (uint256) {
        return preSaleCost;
    }

    function extendPreSaleTime (uint256 _newDate) public onlyOwner {
        if (endpreSale > _newDate){
            revert invalidDate();
        }
        endpreSale = block.timestamp + _newDate;
    }
    
    // change the cost of the token
    function tokenCost (uint256 _price) external checkPrice(_price) onlyOwner {
        preSaleCost = _price;
        emit PriceUpdated(_price);
    }

    // Change the minimum dollar 
    function tokenPriceminimumUSDC (uint256 _price) external checkPrice(_price) onlyOwner {
        minimumUSDC = _price;
        emit PriceUpdated(_price);
    }

    // Change the minimum Eth 
    function tokenPriceminimumEth (uint256 _price) external checkPrice(_price) onlyOwner {
        minimumEth = _price;
        emit PriceUpdated(_price);
    }

    // function deposit BTT to contract
    function depositBTT (uint256 _tokens) external onlyOwner {
       BTT.safeTransferFrom(msg.sender, address(this), _tokens);
    }

    function withdrawPMTtoken () public  onlyOwner {
        uint256 BTTamount = BTT.balanceOf(address(this));
        BTT.transfer(msg.sender, BTTamount);
    }

    function buyTokenWithEth () public payable returns (bool) {
        buyToken();
        return true; 
    }

    // function buy PMT with Eth
    function buyToken() internal returns (bool) {

        if (block.timestamp > endpreSale) {
            revert preSaleIsOver();
        }

        if (msg.value < minimumEth) {
            revert fundsTooLow();
        }

        if (block.timestamp <= endpreSale) {
            costOfToken = preSaleCost;
        }else {
            costOfToken = costAfterPresale;
    }

        // Calculate the amount of tokens to be purchased
        uint256 token = msg.value / costOfToken;

        // Update contract state variables
        soldTokens += token;
        amountRaisedEth += msg.value;

        // Transfer PMT tokens to the buyer's address
        BTT.safeTransfer(msg.sender, token);

        emit BuyToken(msg.sender, token);
        
        return true;
    }

    function buyTokenWithUSDC (uint256 _usdcAmount) public returns (bool) {
        buyWithUSDC(_usdcAmount);
        return true;
    }

    function buyWithUSDC (uint256 _usdcAmount) internal  returns (bool) {

        if (block.timestamp > endpreSale) {
        revert preSaleIsOver();
        }

        if (_usdcAmount < minimumUSDC) {
            revert fundsTooLow();
        }

        if (block.timestamp <  endpreSale) {
            tokenPerUSDC = preSaleCostUSDC;
        }else {
            tokenPerUSDC = costAfterPresaleUSDC;
        }

        uint256 token = _usdcAmount / tokenPerUSDC;

        // Update contract state variables
        soldTokens += token;   
        amountRaisedUSDC += _usdcAmount;
    
         // transfer USDC tokens from the sender to the contract
        USDC.safeTransferFrom(msg.sender, address(this), _usdcAmount);


        // Transfer BTT tokens to the buyer'    
        BTT.safeTransfer(msg.sender, token);

        emit BuyToken(msg.sender, token);
    
        return true;   
    }

    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        amountRaisedEth = 0;
        (bool success,) = msg.sender.call{value: balance}("");
        if (!success) {
            revert failedToSendMoney();
        }
    }
    
    function withdrawUSDC() public onlyOwner {
        uint256 amount = USDC.balanceOf(address(this));
        USDC.safeTransfer(msg.sender, amount);
    }
}