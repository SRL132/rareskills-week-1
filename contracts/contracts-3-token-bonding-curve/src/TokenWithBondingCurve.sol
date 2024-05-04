// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC1363Receiver} from "@openzeppelin/interfaces/IERC1363Receiver.sol";
import {IERC777Recipient} from "erc777Openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {Math} from "@openzeppelin/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";

//TODO: Revise decimals and fix deploy script
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
    //TODO add decimals logic
    uint8 public constant DECIMALS = 18;
    address[] public s_tokenAddresses;
    uint256 public constant SLOPE_FACTOR = 2;
    mapping(address token => uint256 basePrice) public s_tokenBasePrices;

    event TokenBought(address indexed buyer, uint256 amount);
    event TokenSold(address indexed seller, uint256 amount);

    /// @notice Constructor to create a token with a bonding curve
    /// @dev Constructor to create a token with a bonding curve, it implements ERC20 constructor
    /// @param _name name of the token
    /// @param _symbol symbol of the token
    /// @param _tokenAddresses addresses of the tokens to be used in the bonding curve
    /// @param _prices prices of the tokens to be used in the bonding curve
    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _tokenAddresses,
        uint256[] memory _prices
    ) ERC20(_name, _symbol) {
        if (_tokenAddresses.length != _prices.length) {
            revert TokenWithBondingCurve__tokenAddressesAndPricesMustHaveTheSameLength();
        }
        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
            s_tokenBasePrices[_tokenAddresses[i]] = _prices[i];
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
        if (s_tokenBasePrices[msg.sender] == 0) {
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
        if (s_tokenBasePrices[msg.sender] == 0) {
            revert TokenWithBondingCurve__TokenNotSupported();
        }

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

    ///VIEW FUNCTIONS

    function getTokenAddresses() external view returns (address[] memory) {
        return s_tokenAddresses;
    }

    function getTokenBasePrice(
        address _tokenAddress
    ) external view returns (uint256) {
        return s_tokenBasePrices[_tokenAddress];
    }

    function getTotalSupply() external view returns (uint256) {
        return s_totalSupply;
    }
}
