// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
/// @title ERC20 Mock to simulate a compliant ERC20 token
/// @author Sergi Roca Laguna
/// @notice This is a mock contract to simulate an ERC20 token
/// @dev This is a mock ERC20 used to test UntrustedEscrow
contract MyERC20 is ERC20, ERC165 {
    constructor(
        address initialOwner,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(initialOwner, 1000000 * (10 ** uint256(decimals())));
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
