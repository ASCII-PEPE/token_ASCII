# ASCII PEPE Smart Contract Technical Documentation

This document provides a detailed technical overview of the ASCII PEPE smart contract, including its architecture, features, and implementation details. The contract is written in Solidity and follows the ERC20 token standard.

## Contract Architecture

The ASCII PEPE smart contract inherits from the following contracts and libraries:

- **Context**: Provides a base contract for retrieving the `msg.sender` and `msg.data` values.
- **IERC20**: Defines the standard interface for ERC20 tokens.
- **Ownable**: Implements a basic access control mechanism for contract ownership.
- **SafeMath**: Provides safe arithmetic operations to prevent integer overflow and underflow.

The contract uses the following state variables:

- `_tokenBalances`: Mapping to store the token balances of each address.
- `_allowedAmounts`: Mapping to store the allowed token amounts for token transfers between addresses.
- `_isExemptFromFee`: Mapping to indicate whether an address is exempt from fee deductions.
- `_lastBuyBlock`: Mapping to store the block number of the last buy transaction for each address.
- `_feeWallet`: Address of the wallet to receive the collected fees.
- `_tradingStartBlock`: Block number when trading starts.
- `_circulatingSupply`: Current circulating supply of tokens.
- `_antiMevBlocks`: Number of blocks for which the anti-MEV mechanism is active after the trading launch.
- `_initialAdaptiveRebalancingThreshold`: Initial value of the adaptive rebalancing threshold.
- `_finalAdaptiveRebalancingThreshold`: Final value of the adaptive rebalancing threshold.
- `_adaptiveRebalancingThresholdReductionBlocks`: Number of blocks over which the adaptive rebalancing threshold decreases.
- `_initialBuyFeePercentage`: Initial buy fee percentage.
- `_initialSellFeePercentage`: Initial sell fee percentage.
- `_finalBuyFeePercentage`: Final buy fee percentage.
- `_finalSellFeePercentage`: Final sell fee percentage.
- `_buyFeeReductionThreshold`: Number of buy transactions after which the buy fee is reduced.
- `_sellFeeReductionThreshold`: Number of buy transactions after which the sell fee is reduced.
- `_preventSwapThreshold`: Minimum number of buy transactions required before contract can swap tokens.
- `_buyTransactionCount`: Total number of buy transactions.

The contract also includes constants for token decimals, total supply, name, and symbol.

## Uniswap Integration

The contract integrates with Uniswap V2 for liquidity provision and token swapping. It uses the following interfaces and state variables:

- **IUniswapV2Router02**: Interface for interacting with the Uniswap V2 router.
- **IUniswapV2Factory**: Interface for interacting with the Uniswap V2 factory.
- `_uniswapV2Router`: Instance of the Uniswap V2 router.
- `_uniswapV2Pair`: Address of the Uniswap V2 trading pair.
- `_swapEnabled`: Flag to indicate whether token swapping is enabled.
- `_isSwapping`: Flag to indicate whether a swap is currently in progress.

## Fee Structure

The contract implements a flexible fee structure with adjustable buy and sell fees. The fees are determined based on the number of buy transactions and can be reduced over time. The fee percentages are stored in the following state variables:

- `_initialBuyFeePercentage`: Initial buy fee percentage.
- `_initialSellFeePercentage`: Initial sell fee percentage.
- `_finalBuyFeePercentage`: Final buy fee percentage.
- `_finalSellFeePercentage`: Final sell fee percentage.
- `_buyFeeReductionThreshold`: Number of buy transactions after which the buy fee is reduced.
- `_sellFeeReductionThreshold`: Number of buy transactions after which the sell fee is reduced.

The contract also includes a mechanism to exempt certain addresses from fee deductions.

## Access Control

The contract uses the Ownable contract to implement a basic access control mechanism. Only the contract owner can perform certain privileged actions, such as setting the anti-MEV blocks, updating the adaptive rebalancing threshold reduction blocks, and starting the trading.

## Token Transfers

The `_transferTokens` function handles the token transfers and applies the necessary fees and restrictions. It includes the following features:

- Anti-MEV mechanism to prevent front-running and sandwich attacks.
- Maximum transaction amount and maximum wallet balance limits.
- Fee deduction based on the buy and sell fee percentages.
- Automatic token swapping for ETH when certain conditions are met.
- Adaptive rebalancing threshold to maintain a healthy token distribution.
- Token burning when the contract balance exceeds the adaptive rebalancing threshold.

## Token Burning

The contract includes a token burning mechanism to reduce the circulating supply of tokens. The `_burn` function is used to burn tokens from a specific address and update the `_circulatingSupply` accordingly.

The contract owner can manually trigger token burning using the `manualBurn` function.

## Adaptive Rebalancing Threshold

The contract implements an adaptive rebalancing threshold to maintain a healthy token distribution. The threshold starts at a high value and decreases progressively based on the number of blocks since the trading start. The threshold is calculated using the following formula:

```solidity
adaptiveRebalancingThreshold = _initialAdaptiveRebalancingThreshold - ((_initialAdaptiveRebalancingThreshold - _finalAdaptiveRebalancingThreshold) * (blocksRemaining / _adaptiveRebalancingThresholdReductionBlocks))`

When the contract balance exceeds the adaptive rebalancing threshold, the excess tokens are automatically burned.

## Anti-MEV Mechanism

The contract includes an anti-MEV (Miner Extractable Value) mechanism to prevent front-running and sandwich attacks. This mechanism restricts buy transactions to one per block per address during the initial trading period, as specified by the `_antiMevBlocks` variable.

## Utility Functions

The contract provides various utility functions for retrieving token information and performing specific actions:

- `name`: Returns the name of the token.
- `symbol`: Returns the symbol of the token.
- `decimals`: Returns the number of decimal places used by the token.
- `totalSupply`: Returns the total supply of tokens.
- `balanceOf`: Returns the token balance of a specific address.
- `transfer`: Transfers tokens from the caller to a recipient.
- `approve`: Approves an address to spend a specified amount of tokens on behalf of the caller.
- `transferFrom`: Transfers tokens from one address to another on behalf of the approved spender.
- `circulatingSupply`: Returns the current circulating supply of tokens.
- `setAntiMevBlocks`: Allows the contract owner to set the number of anti-MEV blocks.
- `setAdaptiveRebalancingThresholdReductionBlocks`: Allows the contract owner to set the number of blocks for the adaptive rebalancing threshold reduction.
- `manualSwap`: Allows the contract owner to manually trigger a token swap for ETH.
- `manualBurn`: Allows the contract owner to manually burn the contract's token balance.
- `removeLimit`: Allows the contract owner to remove the maximum transaction amount and maximum wallet balance limits.
- `startTrading`: Allows the contract owner to start the trading and initialize the necessary parameters.

---

**Note**: This document is intended for informational purposes only and does not constitute legal or financial advice. It is recommended to consult with a qualified professional for advice specific to your situation.

