// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

/// @title Contract that implments an untrusted escrow
/// @author Sergi Roca Laguna
/// @notice Contract where a buyer can put an arbitrary ERC20 token into a contract and a seller can withdraw it 3 days later
/// @dev Explain to a developer any extra details
contract UntrustedEscrow {
    error UntrustedEscrow__CannotWithdrawBefore3Days();
    error UntrustedEscrow__AmountExceedsBalance();

    struct Deposit {
        address user;
        uint256 timestamp;
        uint256 amount;
    }
    mapping(address depositor => mapping(address => Deposit))
        public s_depositBalances;
    event DepositDone(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    function sellerWithdraw(
        address user,
        address token,
        uint256 amount
    ) external payable {
        if (
            block.timestamp - s_depositBalances[user][token].timestamp < 3 days
        ) {
            revert UntrustedEscrow__CannotWithdrawBefore3Days();
        }

        if (s_depositBalances[user][token].amount < amount) {
            revert UntrustedEscrow__AmountExceedsBalance();
        }
        s_depositBalances[user][token].amount -= amount;
        emit Withdraw(user, token, amount);
    }

    function buyerDeposit(address tokenAddress, uint256 amount) external {
        s_depositBalances[msg.sender][msg.sender].amount += amount;
        s_depositBalances[msg.sender][tokenAddress].timestamp = block.timestamp;
        s_depositBalances[msg.sender][tokenAddress].user = msg.sender;
        s_depositBalances[msg.sender][tokenAddress].amount = amount;
        emit DepositDone(msg.sender, tokenAddress, amount);
    }
}
