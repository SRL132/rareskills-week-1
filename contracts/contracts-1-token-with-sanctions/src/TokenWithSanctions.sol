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

    event AddressBanned(address indexed bannedAddress);
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

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        i_owner = _owner;
        _mint(_owner, FIXED_TOKEN_SUPPLY);
    }

    function banAddress(address _address) external onlyOwner {
        s_bannedAddresses[_address] = true;
        emit AddressBanned(_address);
    }

    function unbanAddress(address _address) external onlyOwner {
        s_bannedAddresses[_address] = false;
        emit AddressUnbanned(_address);
    }

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
