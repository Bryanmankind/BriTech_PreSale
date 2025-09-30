// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract BriTechLabsPreSale is Ownable {

    AggregatorV3Interface internal priceFeed;

    using SafeERC20 for IERC20;

    // Error handeling
    error invalidAmount();
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
    error stalePrice();
    error OverflowDetected();
    error insurficientTokens();
    error tokenSoldOut();

    // payment token to contract 
    IERC20 public USDC;

    // contract native token
    IERC20 public BTT;
    
    uint256 public preSaleStartTime;
    uint256 public endpreSale;
    uint256 public soldTokens;
    uint256 public USDCamountRaised;
    uint256 public amountRaisedEth;

    uint256 public preSaleTokenSupply;

    uint256 public minimumEth = 0.000691 ether; // minimum amount to get one tokens in eth
    uint256 public maxAmountOfTokensPerUser = 10_000 * 1e18; // max amount of tokens per user
    mapping (address => uint256) public userPurchasedTokens;

    uint256 public preSaleCost;

    modifier checkPrice (uint256 _price) {
        if (_price == 0) {
            revert invalidPrice();
        }
        _;
    }
    
    event BttTokenBought (address indexed user,  uint256 amount);
    event PriceUpdated(uint256 newPrice);
    event preSaleEndTimeExtended (uint256 newDate);
    event bttTokenDeposited (uint256 amount);
    event EthWithdrawn(address indexed owner, uint256 amount);
    event UsdcWithdrawn(address indexed owner, uint256 amount);


    constructor (address _tokenAddress, address paymentAdd, uint256 _endPreSale, uint256 _preSaleCost, address _priceFeed, uint256 _preSaleTokenSupply) Ownable(msg.sender) {
        BTT = IERC20(_tokenAddress);
        USDC = IERC20(paymentAdd);
 
        preSaleCost = _preSaleCost;
        preSaleStartTime = block.timestamp;
        endpreSale = _endPreSale;
        preSaleTokenSupply = _preSaleTokenSupply;
        
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    receive() external payable {
        buyTokenWithEth ();
    }

    // Get the cost of BTT token
    function getTokenCost() external view returns (uint256) {
        return preSaleCost;
    }

     function getPriceValue () public view returns (uint256) {
        return _priceValue();
    }

    // Extend the preSale Time 
    function extendPreSaleTime (uint256 _newDate) public onlyOwner {
        if (endpreSale > _newDate){
            revert invalidDate();
        }

        if (endpreSale == _newDate) {
            revert invalidDate();
        }
        endpreSale = _newDate;

        emit preSaleEndTimeExtended(_newDate);
    }
    
    // change the cost of the token
    function setTokenCost (uint256 _price) external checkPrice(_price) onlyOwner {
        preSaleCost = _price;
        emit PriceUpdated(preSaleCost);
    }

    function setMaxAmountOfTokensPerUser (uint256 _amount) external onlyOwner {
        if (_amount == 0) {
            revert invalidAmount();
        }
        if (_amount < maxAmountOfTokensPerUser) {
            revert invalidAmount();
        }
        if (_amount == maxAmountOfTokensPerUser) {
            revert invalidAmount();
        }

        maxAmountOfTokensPerUser = _amount;
    }

    // Change the minimum Eth 
    function tokenPriceminimumEth (uint256 _price) external checkPrice(_price) onlyOwner {
        minimumEth = _price;
        emit PriceUpdated(minimumEth);
    }

    // function deposit BTT to contract
    function depositBTT(uint256 _tokens) external onlyOwner {
        if (_tokens < BTT.totalSupply() / 2) {
            revert invalidAmount();
        }

        require(BTT.transferFrom(msg.sender, address(this), _tokens), "Transfer failed");

        preSaleTokenSupply += _tokens;

        emit bttTokenDeposited (_tokens);
    }


    function buyTokenWithEth () public payable returns (uint256) {
        return buyToken();
    }

    // function buy BTT with Eth
    function buyToken() internal returns (uint256) {

        if (block.timestamp > endpreSale) {
            revert preSaleIsOver();
        }

        if (preSaleTokenSupply == soldTokens) {
            revert tokenSoldOut(); 
        }

        if (msg.value < minimumEth) {
            revert fundsTooLow();
        }

        // Calculate the amount of tokens to be purchased
        uint256 token = msg.value / preSaleCost;

        if (userPurchasedTokens[msg.sender] + token > maxAmountOfTokensPerUser) {
            revert invalidAmount();
        }

        if (preSaleTokenSupply < soldTokens + token) {
            revert insurficientTokens();
        }

        // Update contract state variables
        soldTokens += token;
        userPurchasedTokens[msg.sender] += token;
        amountRaisedEth += msg.value;

        // Transfer BTT tokens to the buyer's address
        BTT.safeTransfer(msg.sender, token);

        emit BttTokenBought (msg.sender, token);
        
        return token;
    }

    function buyTokenWithUSDC (uint256 _usdcAmount) public returns (uint256) {
        return buyWithUSDC(_usdcAmount);
        
    }

   function _priceValue () internal view returns (uint256) {
    ( , int256 USDCFeedPrice, , uint256 updatedAt,) = priceFeed.latestRoundData();

    if (USDCFeedPrice <= 0) {
        revert invalidPrice();
    }

     if (updatedAt + 30 minutes < block.timestamp) {
        revert stalePrice();
    }

     unchecked {
        uint256 price = uint256(USDCFeedPrice); 
        return price / 1e8;
        }
    }

    function _ethEquivalent(uint256 _usdcAmount) internal view returns  (uint256) {

       uint256 price =  _priceValue();

       if (price == 0) {
            revert invalidPrice();
       }

            uint256 ethEquivalent;
        unchecked {
            ethEquivalent = (_usdcAmount * 1e18) / price;
        }
            return ethEquivalent;

    }

    function buyWithUSDC (uint256 _usdcAmount) internal  returns (uint256) {
        if (USDC.allowance(msg.sender, address(this)) < _usdcAmount) {
            revert invalidAmount();
        }

        if (block.timestamp > endpreSale) {
             revert preSaleIsOver();
        }

        if (preSaleTokenSupply == soldTokens) {
            revert tokenSoldOut(); 
        }

       uint256 ethEquivalent = _ethEquivalent(_usdcAmount);

        if (ethEquivalent < minimumEth) {
            revert fundsTooLow();
        }

        uint256 token = ethEquivalent / preSaleCost;

        if (userPurchasedTokens[msg.sender] + token > maxAmountOfTokensPerUser) {
            revert invalidAmount();
        }

        if (preSaleTokenSupply < soldTokens + token) {
            revert insurficientTokens();
        }

        // Update contract state variables
        soldTokens += token;   
        userPurchasedTokens[msg.sender] += token;
        USDCamountRaised += _usdcAmount;
    
         // transfer USDC tokens from the sender to the contract
        USDC.safeTransferFrom(msg.sender, address(this), _usdcAmount);


        // Transfer BTT tokens to the buyer'    
        BTT.safeTransfer(msg.sender, token);

        emit BttTokenBought(msg.sender, token);
    
        return token;   
    }

    // withDraw funds to owners Address.. 
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            revert failedToSendMoney();
        }

        emit EthWithdrawn (msg.sender, balance);
    }
    
    function withdrawUSDC() public onlyOwner {
        uint256 amount = USDC.balanceOf(address(this));
        USDC.safeTransfer(msg.sender, amount);

        emit UsdcWithdrawn (msg.sender, amount);

    }

         // WithdrawBTT Token 
    function withdrawBTTtoken () public  onlyOwner {
        uint256 BTTamount = BTT.balanceOf(address(this));
        BTT.transfer(msg.sender, BTTamount);
    }

    function transferOwnership (address newOwner) public override onlyOwner{
        super.transferOwnership(newOwner);
    }
}