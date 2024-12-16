# DynamicToken Contract

## Overview

`DynamicToken` is a dynamic ERC20 token that implements a minting process with an increasing price model. The mint price starts at a predefined value and increases after each minting operation based on a configurable factor. This contract allows users to mint tokens by paying a specified amount of Ether (BNB). The mint price increases after each successful mint to create an incremental pricing structure.

## Features

- **ERC20 Token:** The contract inherits from an ERC20 token, providing standard functionality for token transfers, approvals, and balances.
- **Dynamic Mint Price:** The mint price for the token starts at a base value and increases by a predefined factor (e.g., 1.015x) after each mint.
- **Payable Mint Function:** Users can mint tokens by sending Ether with their transaction.
- **Reentrancy Protection:** The contract uses the `nonReentrant` modifier to protect against reentrancy attacks.
- **View Functions:** Users can query the current mint price and increase factor at any time.

## Contract Functions

### `mintToken()`
- **Description:** Mints a token to the sender and increases the mint price for future mints.
- **Parameters:** None
- **Modifier:** `payable` (requires Ether to be sent with the transaction)
- **Requirements:** The sender must send at least the current mint price in Ether (`msg.value`).

```solidity
function mintToken() external payable nonReentrant;
