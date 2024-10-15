// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ERC165} from "@openzeppelin/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/utils/introspection/IERC165.sol";
import {ERC165Checker} from "@openzeppelin/utils/introspection/ERC165Checker.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";

/// @title Contract that implments an untrusted escrow with security enhancements.
/// @author Sergi Roca Laguna
/// @notice Contract where a buyer can put an arbitrary ERC20 token into a contract and a seller can withdraw it 3 days later. Tokens have to be approved by the owner before they can be used.
/// @dev This contract implements openzeppelin's ReentrancyGuard and ERC165 as well as SafeERC20 functions and for enhanced security
contract UntrustedEscrow is ERC165, ReentrancyGuard {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    error UntrustedEscrow__CannotWithdrawBefore3Days();
    error UntrustedEscrow__AmountExceedsBalance();
    error UntrustedEscrow__TransferFailed();
    error UntrustedEscrow__NotEnoughMoney();
    error UntrustedEscrow__NotAContract();
    error UntrustedEscrow__NotValidERC20();
    error UntrustedEscrow__ZeroAmountSent();
    error UntrustedEscrow__CannotUpdateSaleBefore4Days();

    struct Deposit {
        address user;
        uint256 timestamp;
        uint256 amount;
        uint256 price;
    }

    address immutable i_owner;

    mapping(address depositor => mapping(address => Deposit))
        public s_depositBalances;

    mapping(address approvedToken => bool) public s_approvedTokens;

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

    /// @notice This is an event to notify that a token has been approved
    /// @dev This event is activated when tokens are approved and return the relevant address to be rendered or tracked
    /// @param token The address of the token that was approved
    event TokenApproved(address indexed token);

    /// @notice This is an event to notify that a token has been revoked
    /// @dev This event is activated when tokens are revoked and return the relevant address to be rendered or tracked
    /// @param token The address of the token that was revoked
    event TokenRevoked(address indexed token);

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert UntrustedEscrow__NotAContract();
        }
        _;
    }

    modifier onlyApprovedToken(address _token) {
        if (!s_approvedTokens[_token]) {
            revert UntrustedEscrow__NotValidERC20();
        }
        _;
    }

    /// @notice This is the constructor of the contract
    /// @dev This constructor initializes the contract and sets the owner, only they will be able to approve tokens
    /// @param _owner The address of the owner of the contract, only they will be able to approve tokens
    constructor(address _owner) {
        i_owner = _owner;
    }

    /// @notice This function allows a seller to withdraw tokens from the contract
    /// @dev This function allows a seller to withdraw tokens from the contract, it implements a nonReentrant modifier to avoid reentrancy attacks, it also applies CEI pattern for enhanced security
    /// @param _user The address of the user that made the deposit
    /// @param _token The address of the token that was deposited
    /// @param _amount The amount of tokens to withdraw
    function sellerWithdraw(
        address _user,
        address _token,
        uint256 _amount
    ) external payable nonReentrant onlyApprovedToken(_token) {
        if (_amount == 0) {
            revert UntrustedEscrow__ZeroAmountSent();
        }

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
        s_depositBalances[_user][_token].amount -= _amount;

        (bool success, ) = _user.call{value: msg.value}("");
        if (!success) {
            revert UntrustedEscrow__TransferFailed();
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);

        if (IERC20(_token).balanceOf(msg.sender) < _amount) {
            revert UntrustedEscrow__TransferFailed();
        }

        emit Withdraw(_user, _token, _amount);
    }

    /// @notice This function allows a buyer to deposit tokens into the contract, to avoid malicious delaying, it can only be updated after 4 days so that sellers have a chance to withdraw
    /// @dev This function allows a buyer to deposit tokens into the contract. The function implements nonReentrant to avoid reentrancy attacks, it also applies CEI pattern for enhanced security
    /// @param _tokenAddress The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _price The price of the tokens
    function buyerDeposit(
        address _tokenAddress,
        uint256 _amount,
        uint256 _price
    ) external nonReentrant onlyApprovedToken(_tokenAddress) {
        if (!_tokenAddress.supportsInterface(type(IERC20).interfaceId)) {
            revert UntrustedEscrow__NotValidERC20();
        }

        if (_amount == 0) {
            revert UntrustedEscrow__ZeroAmountSent();
        }

        if (
            s_depositBalances[msg.sender][_tokenAddress].timestamp > 0 &&
            block.timestamp -
                s_depositBalances[msg.sender][_tokenAddress].timestamp <
            4 days
        ) {
            revert UntrustedEscrow__CannotUpdateSaleBefore4Days();
        }

        s_depositBalances[msg.sender][_tokenAddress].amount += _amount;
        s_depositBalances[msg.sender][_tokenAddress].timestamp = block
            .timestamp;
        s_depositBalances[msg.sender][_tokenAddress].user = msg.sender;
        s_depositBalances[msg.sender][_tokenAddress].amount = _amount;
        s_depositBalances[msg.sender][_tokenAddress].price = _price;

        IERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (IERC20(_tokenAddress).balanceOf(address(this)) < _amount) {
            revert UntrustedEscrow__TransferFailed();
        }

        emit DepositDone(msg.sender, _tokenAddress, _amount);
    }

    /// @notice This function allows the owner to approve tokens to be used in the contract
    /// @dev This function allows the owner to approve tokens to be used in the contract
    /// @param _token The address of the token to approve
    function approveToken(address _token) external onlyOwner {
        s_approvedTokens[_token] = true;
        emit TokenApproved(_token);
    }

    /// @notice This function allows the owner to revoke tokens to be used in the contract
    /// @dev This function allows the owner to revoke tokens to be used in the contract
    /// @param _token The address of the token to revoke
    function revokeToken(address _token) external onlyOwner {
        s_approvedTokens[_token] = false;
        emit TokenRevoked(_token);
    }
}
