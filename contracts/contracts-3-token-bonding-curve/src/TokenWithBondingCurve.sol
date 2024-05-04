// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC1363Receiver} from "openzeppelin-contracts/contracts/interfaces/IERC1363Receiver.sol";

/// @title Token sale and buyback with bonding curve.
/// @author Sergi Roca Laguna
/// @notice The more tokens a user buys, the more expensive the token becomes. It implements a linear bonding curve. The price increases in quadratically every time a token is bought and decreases in quadratically every time a token is sold.
/// @dev Token implements ERC20 extended with ERC1363 receiver interface.
contract TokenWithBondingCurve is ERC20, IERC1363Receiver {
    error TokenWithBondingCurve__TokenAddressesAndPricesMustHaveTheSameLength();
    error TokenWithBondingCurve__PriceExceedsMaxPrice();
    error TokenWithBondingCurve__TokenNotSupported();
    error TokenWithBondingCurve__AmountMustBeGreaterThanZero();
    error TokenWithBondingCurve__TokensToReturnBelowMinimumSet();

    uint256 s_totalSupply = 0;
    uint256 constant DECIMALS = 9;
    mapping(address token => uint256 basePrice) s_tokenBasePrices;
    address[] s_tokenAddresses;
    uint256 public constant SLOPE_FACTOR = 2;

    event TokenBought(address indexed buyer, uint256 amount);
    event TokenSold(address indexed seller, uint256 amount);

    /// @notice Constructor to create a token with a bonding curve
    /// @dev Constructor to create a token with a bonding curve, it implements ERC20 constructor
    /// @param name name of the token
    /// @param symbol symbol of the token
    /// @param tokenAddresses addresses of the tokens to be used in the bonding curve
    /// @param prices prices of the tokens to be used in the bonding curve
    constructor(
        string memory name,
        string memory symbol,
        address[] memory tokenAddresses,
        uint256[] memory prices
    ) ERC20(name, symbol) {
        if (tokenAddresses.length != prices.length) {
            revert TokenWithBondingCurve__TokenAddressesAndPricesMustHaveTheSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; ++i) {
            s_tokenBasePrices[tokenAddresses[i]] = prices[i];
            s_tokenAddresses.push(tokenAddresses[i]);
        }
    }

    ///EXTERNAL FUNCTIONS

    /// @inheritdoc	IERC1363Receiver
    function onTransferReceived(
        address operator,
        address from,
        uint256 amount,
        bytes memory data
    ) external returns (bytes4) {
        if (s_tokenBasePrices[msg.sender] == 0) {
            revert TokenWithBondingCurve__TokenNotSupported();
        }
        //get max price from data
        uint256 maxPrice = abi.decode(data, (uint256));
        buy(amount, maxPrice, from);
        return this.onTransferReceived.selector;
    }

    /// @notice Function to buy tokens
    /// @dev Function to buy tokens, it calculates the price of the token and mints the token to the buyer
    /// @param amount amount of external tokens received to purchase TBC
    /// @param maxPrice maximum price the buyer is willing to pay
    /// @param from address of the buyer
    function buy(uint256 amount, uint256 maxPrice, address from) internal {
        if (amount == 0) {
            revert TokenWithBondingCurve__AmountMustBeGreaterThanZero();
        }
        uint256 price = _calculateBuyPrice(amount);
        if (price > maxPrice) {
            revert TokenWithBondingCurve__PriceExceedsMaxPrice();
        }
        _mint(from, price);
        unchecked {
            s_totalSupply += price;
        }

        emit TokenBought(from, price);
    }

    /// @notice Function to sell tokens
    /// @dev Function to sell tokens, it calculates the price of the token, burns the token from the seller and returns the external token to the seller
    /// @param amountOfTBCToSell amount of TBC to sell
    /// @param tokenAddress address of the token to return
    /// @param minimumTokensToReturn minimum amount of tokens to return
    function sellFor(
        uint256 amountOfTBCToSell,
        address tokenAddress,
        uint256 minimumTokensToReturn
    ) external {
        uint256 tokensToReturn = _calculateSellPrice(amountOfTBCToSell);
        if (tokensToReturn < minimumTokensToReturn) {
            revert TokenWithBondingCurve__TokensToReturnBelowMinimumSet();
        }
        _burn(msg.sender, amountOfTBCToSell);
        s_totalSupply -= amountOfTBCToSell;
        ERC20(tokenAddress).transfer(msg.sender, tokensToReturn);
        emit TokenSold(msg.sender, amountOfTBCToSell);
    }

    ///HELPER FUNCTIONS
    /// @param amount amount of external tokens received to purchase TBC
    /// @return amountOfTokensBought newcalculated prices
    function _calculateBuyPrice(
        uint256 amount
    ) private view returns (uint256 amountOfTokensBought) {
        //total supply of TBC
        //f = function
        // where x is the total token supply
        // and m is the slope factor
        //f(x) = m * (x^2)
        uint256 latestPrice = SLOPE_FACTOR * s_totalSupply ** 2;
        uint256 newPrice = SLOPE_FACTOR * (s_totalSupply + amount) ** 2;
        amountOfTokensBought = newPrice - latestPrice;
    }
    /// @param amount amount of external tokens received to sell TBC
    /// @return amountOfTokensSold newcalculated prices
    function _calculateSellPrice(
        uint256 amount
    ) private view returns (uint256 amountOfTokensSold) {
        //f = function
        // where x is the total token supply
        // and m is the slope factor
        //f(x) = m * (x^2)
        uint256 latestPrice = sqrt(SLOPE_FACTOR * s_totalSupply) / 2;
        uint256 newPrice = sqrt(SLOPE_FACTOR * (s_totalSupply - amount)) / 2;
        amountOfTokensSold = latestPrice - newPrice;
        return amountOfTokensSold;
    }

    /// @dev Function to calculate the square root of a number
    /// @param x number to calculate the square root for
    /// @return square root of x
    function sqrt(uint256 x) private pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    ///VIEW FUNCTIONS

    function getTokenAddresses() external view returns (address[] memory) {
        return s_tokenAddresses;
    }

    function getTokenBasePrice(
        address tokenAddress
    ) external view returns (uint256) {
        return s_tokenBasePrices[tokenAddress];
    }

    function getTotalSupply() external view returns (uint256) {
        return s_totalSupply;
    }
}
