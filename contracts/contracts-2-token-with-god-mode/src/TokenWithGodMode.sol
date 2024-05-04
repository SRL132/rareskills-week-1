// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

error TokenWithGodMode__NotOwner();

/// @title Token that allows the owner to transfer tokens between addresses at will.
/// @author Sergi Roca Laguna
/// @notice This token has a fixed supply of 500 units. It allows the owner to transfer tokens between addresses at will.
/// @dev This token implements an ERC20 with fixed token supply and the ability for the owner to the owner to transfer tokens between addresses at will.
contract TokenWithGodMode is ERC20 {
    uint256 public constant FIXED_TOKEN_SUPPLY = 500;
    address public i_owner;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert TokenWithGodMode__NotOwner();
        _;
    }

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

    /// @notice Function that allows the owner to transfer tokens between addresses at will
    /// @dev Function that allows the owner to directly call internal transfer function, skipping the need for an allowance
    /// @param _sender The address whose tokens will be transferred
    /// @param _recipient The address of the recipient
    /// @param _amount The amount of tokens to transfer
    function godTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public onlyOwner {
        _transfer(_sender, _recipient, _amount);
    }
}
