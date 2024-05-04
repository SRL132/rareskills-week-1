// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

/// @title Contract that implments an untrusted escrow
/// @author Sergi Roca Laguna
/// @notice Contract where a buyer can put an arbitrary ERC20 token into a contract and a seller can withdraw it 3 days later
/// @dev This contract implements openzeppelin's ReentrancyGuard and ERC165
contract UntrustedEscrow is ERC165, ReentrancyGuard {
    using ERC165Checker for address;
    error UntrustedEscrow__CannotWithdrawBefore3Days();
    error UntrustedEscrow__AmountExceedsBalance();
    error UntrustedEscrow__TransferFailed();
    error UntrustedEscrow__NotEnoughMoney();
    error UntrustedEscrow__NotAContract();
    error UntrustedEscrow__NotERC20();

    struct Deposit {
        address user;
        uint256 timestamp;
        uint256 amount;
        uint256 price;
    }

    mapping(address depositor => mapping(address => Deposit))
        public s_depositBalances;

    /// @notice This is an event to notify that a deposit has been done
    /// @dev This event is activated when deposits are done and return the relevant data to be rendered or tracked
    /// @param user The address of the user that made the deposit
    /// @param token The address of the token that was deposited
    /// @param amount The amount of tokens deposited
    event DepositDone(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    /// @notice This is an event to notify that a withdrawal has been done
    /// @dev This event is activated when withdrawals are done and return the relevant data to be rendered or tracked
    /// @param user The address of the user that made the withdrawal
    /// @param token The address of the token that was withdrawn
    /// @param amount The amount of tokens withdrawn
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    /// @notice This function allows a seller to withdraw tokens from the contract
    /// @dev This function allows a seller to withdraw tokens from the contract, it implements a nonReentrant modifier to avoid reentrancy attacks
    /// @param _user The address of the user that made the deposit
    /// @param _token The address of the token that was deposited
    /// @param _amount The amount of tokens to withdraw
    function sellerWithdraw(
        address _user,
        address _token,
        uint256 _amount
    ) external payable nonReentrant {
        if (
            block.timestamp - s_depositBalances[_user][_token].timestamp <
            3 days
        ) {
            revert UntrustedEscrow__CannotWithdrawBefore3Days();
        }

        if (s_depositBalances[_user][_token].amount < _amount) {
            revert UntrustedEscrow__AmountExceedsBalance();
        }

        if (msg.value < (s_depositBalances[_user][_token].price * _amount)) {
            revert UntrustedEscrow__NotEnoughMoney();
        }

        IERC20(_token).transfer(msg.sender, _amount);

        s_depositBalances[_user][_token].amount -= _amount;
        (bool success, ) = _user.call{value: msg.value}("");
        if (!success) {
            revert UntrustedEscrow__TransferFailed();
        }
        emit Withdraw(_user, _token, _amount);
    }

    /// @notice This function allows a buyer to deposit tokens into the contract
    /// @dev This function allows a buyer to deposit tokens into the contract
    /// @param _tokenAddress The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _price The price of the tokens
    function buyerDeposit(
        address _tokenAddress,
        uint256 _amount,
        uint256 _price
    ) external {
        if (!_tokenAddress.supportsInterface(type(IERC20).interfaceId)) {
            revert UntrustedEscrow__NotERC20();
        }

        bool success = IERC20(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (!success) {
            revert UntrustedEscrow__TransferFailed();
        }

        s_depositBalances[msg.sender][_tokenAddress].amount += _amount;
        s_depositBalances[msg.sender][_tokenAddress].timestamp = block
            .timestamp;
        s_depositBalances[msg.sender][_tokenAddress].user = msg.sender;
        s_depositBalances[msg.sender][_tokenAddress].amount = _amount;
        s_depositBalances[msg.sender][_tokenAddress].price = _price;

        emit DepositDone(msg.sender, _tokenAddress, _amount);
    }
}
