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
        address _initialOwner,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _mint(_initialOwner, 1000000 * (10 ** uint256(decimals())));
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}
