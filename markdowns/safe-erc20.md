# Safe ERC-20

## Overview
- SafeERC20 from openzeppelin documentation ([link](https://docs.openzeppelin.com/contracts/2.x/api/token/erc20#SafeERC20))
- SafeERC20 from openzeppelin code ([link](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol))

## Why does the SafeERC20 program exist?

SafeERC-20 exists for the following reasons:

**Implement Wrapper functions with checks** 
SafeErc-20 implements wrapper functions onto elemental ERC-20 functions to make sure some security checks are made before said functions are activated, such as `safeTransfer` for `transfer`.

## When should SafeERC20 be used?
It should be used in cases such as follows:

**Where the fact that Transfer() & transferFrom() do not revert is critical on ERC20-related implementations**
Many ERC functions return booleans and do not revert on failure. With safeERC20 you can do this to enhance security against behaviour of non-standard ERC20 tokens.

**Mitigate front-running attacks**
SafeERC20 provide functions such as `increaseAllowance` and `decreaseAllowance`, which help to mitigate the vulnerabilities of the vanilla approve.

**Solmate’s implementation of ERC20 SafeTransferLib does not check if the token is really a contract**
Solmate smart contracts are an alternative to OpenZeppelin’s ones. While they are more cost-effective in terms of gas, they skip vital checks such as whether a given address is actually a contract (has code in it). SafeERC can help provide this kind of checks.