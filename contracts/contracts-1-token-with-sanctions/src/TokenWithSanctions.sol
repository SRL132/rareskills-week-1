// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

error TokenWithSanctions__NotOwner();
error TokenWithSanctions__SenderBanned();
error TokenWithSanctions__RecipientBanned();

/// @title Token that allows the owner to ban specified addresses from sending and receiving tokens.
/// @author Sergi Roca Laguna
/// @notice This token has a fixed supply of 500 units. It allows the owner to ban addresses, which will not be able to send or receive tokens.
/// @dev This token implements an ERC20 with fixed token supply and the ability to ban addresses.
contract TokenWithSanctions is ERC20 {
    uint256 public constant FIXED_TOKEN_SUPPLY = 500;
    address public i_owner;
    mapping(address => bool) public s_bannedAddresses;

    /// @notice Event to notify that an address has been banned
    /// @dev Event to notify that an address has been banned, which will not be able to transfer or receive tokens
    /// @param bannedAddress The address that has been banned
    event AddressBanned(address indexed bannedAddress);
    /// @notice Event to notify that an address has been unbanned
    /// @dev Event to notify that an address has been unbanned, which will be able to transfer or receive tokens again
    /// @param bannedAddress The address that will no longer be banned
    event AddressUnbanned(address indexed bannedAddress);

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert TokenWithSanctions__NotOwner();
        _;
    }

    modifier senderNotBanned(address account) {
        if (s_bannedAddresses[account])
            revert TokenWithSanctions__SenderBanned();
        _;
    }

    modifier recipientNotBanned(address account) {
        if (s_bannedAddresses[account])
            revert TokenWithSanctions__RecipientBanned();
        _;
    }
    /// @notice Constructor to create a token with a fixed supply
    /// @dev Constructor to create a token with a fixed supply, it implements ERC20 constructor and mints an immutable supply of tokens
    /// @param _owner address of the owner of the token
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        i_owner = _owner;
        _mint(_owner, FIXED_TOKEN_SUPPLY);
    }
    /// @notice Function that allows the owner to ban an address, which will not be able to transfer or receive tokens unless unbanned
    /// @dev Function that allows the owner to ban an address, which will not be able to transfer or receive tokens unless unbanned
    /// @param _address The address to be banned
    function banAddress(address _address) external onlyOwner {
        s_bannedAddresses[_address] = true;
        emit AddressBanned(_address);
    }
    /// @notice Function that allows the owner to unban an address, which will be able to transfer or receive tokens again
    /// @dev Function that allows the owner to unban an address, which will be able to transfer or receive tokens again
    /// @param _address The address to be unbanned
    function unbanAddress(address _address) external onlyOwner {
        s_bannedAddresses[_address] = false;
        emit AddressUnbanned(_address);
    }
    /// @notice Function that allows non-banned addresses to transfer tokens
    /// @dev Function that allows addresses not in s_bannedAddresses to transfer tokens
    /// @param recipient The address of the recipient
    /// @param amount The amount of tokens to transfer
    /// @return a bool to tell whether the transfer was successful
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        override
        senderNotBanned(msg.sender)
        recipientNotBanned(recipient)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }
    /// @notice Function that allows non-banned addresses to transfer and receive tokens on behalf of another address
    /// @dev Function that allows addresses not in s_bannedAddresses to transfer and receive tokens on behalf of another address
    /// @param sender The address of the sender
    /// @param recipient The address of the recipient
    /// @param amount The amount of tokens to transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        senderNotBanned(sender)
        recipientNotBanned(recipient)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }
}
