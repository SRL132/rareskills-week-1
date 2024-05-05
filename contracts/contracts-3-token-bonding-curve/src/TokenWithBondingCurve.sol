// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC1363Receiver} from "@openzeppelin/interfaces/IERC1363Receiver.sol";
import {IERC777Recipient} from "erc777Openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {Math} from "@openzeppelin/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//TODO: Revise decimals
/// @title Token sale and buyback with bonding curve.
/// @author Sergi Roca Laguna
/// @notice The more tokens a user buys, the more expensive the token becomes. It implements a linear bonding curve. The price increases in quadratically every time a token is bought and decreases in quadratically every time a token is sold.
/// @dev Token implements ERC20 extended with ERC1363 receiver interface.
contract TokenWithBondingCurve is
    ERC20,
    IERC1363Receiver,
    IERC777Recipient,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    error TokenWithBondingCurve__tokenAddressesAndPricesMustHaveTheSameLength();
    error TokenWithBondingCurve__PriceExceedsMaxPrice();
    error TokenWithBondingCurve__TokenNotSupported();
    error TokenWithBondingCurve__AmountMustBeGreaterThanZero();
    error TokenWithBondingCurve__TokensToReturnBelowMinimumSet();

    uint256 public s_totalSupply = 0;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;
    address[] public s_tokenAddresses;

    uint256 public constant SLOPE_FACTOR = 2;
    mapping(address token => address priceFeed) public s_tokenUsdPriceFeeds;

    event TokenBought(address indexed buyer, uint256 amount);
    event TokenSold(address indexed seller, uint256 amount);

    /// @notice Constructor to create a token with a bonding curve
    /// @dev Constructor to create a token with a bonding curve, it implements ERC20 constructor
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @param _tokenAddresses addresses of the tokens to be used in the bonding curve
    /// @param _priceFeeds Chainlink USD price feeds for the tokens
    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _tokenAddresses,
        address[] memory _priceFeeds
    ) ERC20(_name, _symbol) {
        if (_tokenAddresses.length != _priceFeeds.length) {
            revert TokenWithBondingCurve__tokenAddressesAndPricesMustHaveTheSameLength();
        }
        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
            s_tokenUsdPriceFeeds[_tokenAddresses[i]] = _priceFeeds[i];
            s_tokenAddresses.push(_tokenAddresses[i]);
        }
    }

    ///EXTERNAL FUNCTIONS

    /// @inheritdoc	IERC1363Receiver
    function onTransferReceived(
        address _operator,
        address _from,
        uint256 _amount,
        bytes memory _data
    ) external returns (bytes4) {
        if (s_tokenUsdPriceFeeds[msg.sender] == address(0)) {
            revert TokenWithBondingCurve__TokenNotSupported();
        }

        uint256 maxPrice = abi.decode(_data, (uint256));
        _buy(_amount, maxPrice, _from);
        return this.onTransferReceived.selector;
    }

    ///@inheritdoc IERC777Recipient
    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _userData,
        bytes calldata _operatorData
    ) external {
        if (s_tokenUsdPriceFeeds[msg.sender] == address(0)) {
            revert TokenWithBondingCurve__TokenNotSupported();
        }
        _getUsdValue(_from, _amount);
        uint256 maxPrice = abi.decode(_userData, (uint256));
        _buy(_amount, maxPrice, _from);
    }

    /// @notice Function to buy tokens
    /// @dev Function to buy tokens, it calculates the price of the token and mints the token to the buyer
    /// @param _amount amount of external tokens received to purchase TBC
    /// @param _maxPrice maximum price the buyer is willing to pay
    /// @param _from address of the buyer
    function _buy(uint256 _amount, uint256 _maxPrice, address _from) internal {
        if (_amount == 0) {
            revert TokenWithBondingCurve__AmountMustBeGreaterThanZero();
        }
        uint256 price = _calculateBuyPrice(_amount);
        if (price > _maxPrice) {
            revert TokenWithBondingCurve__PriceExceedsMaxPrice();
        }
        _mint(_from, price);
        unchecked {
            s_totalSupply += price;
        }

        emit TokenBought(_from, price);
    }

    /// @notice Function to sell tokens
    /// @dev Function to sell tokens, it calculates the price of the token, burns the token from the seller and returns the external token to the seller
    /// @param _amountOfTBCToSell amount of TBC to sell
    /// @param _tokenAddress address of the token to return
    /// @param _minimumTokensToReturn minimum amount of tokens to return
    function sellFor(
        uint256 _amountOfTBCToSell,
        address _tokenAddress,
        uint256 _minimumTokensToReturn
    ) external nonReentrant {
        uint256 tokensToReturn = _calculateSellPrice(_amountOfTBCToSell);
        if (tokensToReturn < _minimumTokensToReturn) {
            revert TokenWithBondingCurve__TokensToReturnBelowMinimumSet();
        }
        _burn(msg.sender, _amountOfTBCToSell);
        s_totalSupply -= _amountOfTBCToSell;
        IERC20(_tokenAddress).safeTransfer(msg.sender, tokensToReturn);
        emit TokenSold(msg.sender, _amountOfTBCToSell);
    }

    ///HELPER FUNCTIONS
    /// @dev Function that calculates the price of the token when buying by applying the following bonding curve:
    /// f(x) = m * (x^2)
    /// where x is the total token supply and m is the slope factor
    /// @param _amount amount of external tokens received to purchase TBC
    /// @return _amountOfTokensBought newcalculated prices
    function _calculateBuyPrice(
        uint256 _amount
    ) private view returns (uint256 _amountOfTokensBought) {
        uint256 latestPrice = SLOPE_FACTOR * s_totalSupply ** 2;
        uint256 newPrice = SLOPE_FACTOR * (s_totalSupply + _amount) ** 2;
        _amountOfTokensBought = newPrice - latestPrice;
    }

    /// @dev Function that calculates the price of the token when selling by applying the following bonding curve:
    /// f(x) = m * (x^2)
    /// where x is the total token supply and m is the slope factor
    /// @param _amount amount of external tokens received to sell TBC
    /// @return _amountOfTokensSold newcalculated prices
    function _calculateSellPrice(
        uint256 _amount
    ) private view returns (uint256 _amountOfTokensSold) {
        uint256 latestPrice = Math.sqrt(SLOPE_FACTOR * s_totalSupply) / 2;
        uint256 newPrice = Math.sqrt(SLOPE_FACTOR * (s_totalSupply - _amount)) /
            2;
        _amountOfTokensSold = latestPrice - newPrice;
        return _amountOfTokensSold;
    }

    //TODO: what happens if oracle fails? It is an off-chain source and everything can happen
    /// @notice This function returns the USD values for the contract tokens
    /// @dev This function returns the USD values for the contract tokens via Chainlink USD price feeds
    /// @param _token address of the token
    /// @param _amount amount of the tokens to calculate the USD value for
    /// @return uint256 USD value of the amount of given token
    function _getUsdValue(
        address _token,
        uint256 _amount
    ) private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_tokenUsdPriceFeeds[_token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // 1 ETH = 1000 USD
        // The returned value from Chainlink will be 1000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        // We want to have everything in terms of WEI, so we add 10 zeros at the end
        return
            ((uint256(price) * ADDITIONAL_FEED_PRECISION) * _amount) /
            PRECISION;
    }

    /// @notice This function returns the token amount for a given USD amount
    /// @dev This function returns the token amount for a given USD amount via Chainlink USD price feeds
    /// @param _token address of the token
    /// @param _usdAmountInWei amount of USD in WEI to calculate the token amount for
    /// @return uint256 token amount for the given USD amount
    function getTokenAmountFromUsd(
        address _token,
        uint256 _usdAmountInWei
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_tokenUsdPriceFeeds[_token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // $100e18 USD Debt
        // 1 ETH = 2000 USD
        // The returned value from Chainlink will be 2000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        return ((_usdAmountInWei * PRECISION) /
            (uint256(price) * ADDITIONAL_FEED_PRECISION));
    }

    ///VIEW FUNCTIONS

    /// @notice This function returns the price feed address for a given token
    /// @dev This function returns the price feed address for a given token
    /// @param _token address of the token
    /// @return address price feed address for the given token
    function getTokenPriceFeed(address _token) external view returns (address) {
        return s_tokenUsdPriceFeeds[_token];
    }

    /// @notice This function returns the addresses of the allowed tokens
    /// @dev This function returns the addresses of the allowed tokens
    /// @return address[] memory addresses of the allowed tokens
    function getTokenAddresses() external view returns (address[] memory) {
        return s_tokenAddresses;
    }

    /// @notice This function returns the USD value for a given amount of a given token
    /// @dev This function returns the USD value for a given amount of a given token
    /// @param _token address of the token
    /// @param _amount amount of USD corresponding to a specific token
    function getUsdValue(
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        return _getUsdValue(_token, _amount);
    }
}
