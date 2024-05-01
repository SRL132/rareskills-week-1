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

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        i_owner = _owner;
        _mint(_owner, FIXED_TOKEN_SUPPLY);
    }

    function godTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public onlyOwner {
        _transfer(sender, recipient, amount);
    }
}
