# ERC-777 and ERC-1363 Problems

## What problems do ERC-777 and ERC-1363 solve?

ERC-777 and ERC-1363 both address issues related to ERC-20:

1. **Token Transfer:** ERC-20 requires two steps when transferring tokens: an `approve` step to assign an allowance, and a `transfer` step that can allows users send an amount of tokens up to their specified allowance. ERC-777 simplifies this process by allowing it to be done with hooks, which enable callback functions (`tokensReceived`) to happen when transfers are received.

2. **Security of Double Transactions:** The double transactions mentioned above mean that transfer functions can be front-run. For example, if an allowance function is set for user U by mistake and the owner is trying to send a second `approve` transaction to fix it, this user can front-run to take advantage of the already implemented `approve` in order to transfer tokens before the second approval gets implemented. This effectively allows the user to transfer tokens twice.

## Why was ERC-1363 introduced, and what issues are there with ERC-777?
ERC-777's hook functionality can potentially allow for reentrancy attacks, making the token prone to additional attack vectors. ERC-1363 was introduced to address these issues. It allows for the direct call of `onTransferReceived` functions and includes `safeTransfer` functions that ensure the target contract has the necessary functionality to act upon received tokens.