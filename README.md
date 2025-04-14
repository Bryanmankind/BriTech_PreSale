# BTT Token Presale Contract

This Solidity smart contract allows users to participate in a presale event by purchasing **BTT tokens** using **ETH** or **USDC** tokens. The contract is developed using **Solidity** and **Foundry**.

## Features

- **Purchase BTT Tokens:** Users can buy BTT tokens with ETH or USDC during the presale.
- **Presale Duration:** The contract supports a specific duration for the presale period.
- **Token Allocation:** A fixed amount of BTT tokens are available for sale.
- **Multiple Payment Options:** Users can participate using either ETH or USDC.
- **Fund Withdrawal:** The collected ETH and USDC can be withdrawn by the contract owner.

## Requirements

- **Solidity Version:** 0.8.x
- **Foundry Framework**

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Bryanmankind/BriTech_PreSale.git
   cd BriTech_PreSale
   ```

2. Install dependencies:

   ```bash
   forge install
   ```

3. Compile the contract:

   ```bash
   forge build
   ```

4. Run the tests:

   ```bash
   forge test
   ```

## How to Use

1. **Buy Tokens with ETH:**
   Send ETH to the contract address during the presale period to receive BTT tokens. The conversion rate and other details are defined within the contract.

2. **Buy Tokens with USDC:**
   Approve the contract to spend your USDC tokens, then call the contract to purchase BTT tokens with USDC.

3. **Withdrawal (Owner only):**
   The contract owner can withdraw the collected ETH and USDC after the presale period ends.

## Contracts

- `briTechPreSale.sol`: Main contract for the BTT token presale, handling purchases, and managing funds.
  
## Deployment

You can deploy the contract using your preferred Ethereum development environment (e.g., Hardhat, Foundry). Make sure you have the correct ETH and USDC addresses for the chosen network.

## License

This project is licensed under the MIT License.