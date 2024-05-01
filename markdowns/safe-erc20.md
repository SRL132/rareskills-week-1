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

**Transfer() & transferFrom() do not revert**
According to ERC20 both transfer and transferFrom return a boolean and do not revert. So, in order to revert the state in case that the functions fail, you have to check the return value and revert yourself when applicable.
Furthermore, you cannot guarantee that the boolean will be returned as expected, so the best practice is that you should also decode the return data and check if it’s “true”:
```javascript
(bool success, bytes returndata) = address(token).call(data);
require(success || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
```
**Solmate’s implementation of ERC20 SafeTransferLib does not check if the token is really a contract**
Solmate smart contracts are an alternative to OpenZeppelin’s ones. Where they shine at, is gas usage. Through low-level assembly and leaving off some sanity checks, they are able to reduce gas costs compared to competitors.
One of such smart contracts is SafeTransferLib, which you can use for ERC20 to automatically revert when a function returns false (e.g. transfer). It’s library similar to OpenZeppelin’s SafeERC20 lib, but it has one particular issue that may have some serious consequences, and that’s because the transfer lib is not so safe when it comes to checking whom it does call. It does not verify that the target address of ERC20 is really a contract. And here’s an issue, that I describe in the next paragraph.
Let’s say that you have a smart contract that changes its state when you pass an ERC20 address to transfer from. Because you use SafeTransferLib, you’re sure that if something fails, it will revert, so your changes to state will also revert. So, you don’t put the ERC20 address by mistake and it’s set to 0x0000000000000000000000000000000000000000 by default. But it’s not a problem, because such a transaction will fail, or doesn’t it? Well, it uses low-level call, and any call to EOA (externally owned account — account that does not have any code attached, technically), given that the amount of gas left is sufficient, will succeed. And you now have a broken state of your smart contract that you did not account for.
As a mitigation step to this issue is to verify the address code size before interacting with it, or use OpenZeppelin’s SafeERC20, which does just that.