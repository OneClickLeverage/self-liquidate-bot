pragma solidity ^0.7.0;

/**
 * @title Uniswap v2.
 * @dev Decentralized Exchange.
 */

import {TokenInterface} from "../../common/interfaces.sol";
import {Helpers} from "./helpers.sol";
import "hardhat/console.sol";

abstract contract UniswapResolver is Helpers {
    function buy(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt,
        uint256 unitAmt
    ) external payable {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
            buyAddr,
            sellAddr
        );
        address[] memory paths = getPaths(
            address(_buyAddr),
            address(_sellAddr)
        );

        uint256 _slippageAmt = convert18ToDec(
            _sellAddr.decimals(),
            wmul(unitAmt, convertTo18(_buyAddr.decimals(), buyAmt))
        );

        checkPair(paths);
        uint256 _expectedAmt = getExpectedSellAmt(paths, buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        bool isEth = address(_sellAddr) == wethAddr;
        convertEthToWeth(isEth, _sellAddr, _expectedAmt);
        approve(_sellAddr, address(router), _expectedAmt);

        router.swapTokensForExactTokens(
            buyAmt,
            _expectedAmt,
            paths,
            address(this),
            block.timestamp + 1
        );

        isEth = address(_buyAddr) == wethAddr;
        convertWethToEth(isEth, _buyAddr, buyAmt);
    }

    function sell(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt
    ) external payable {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
            buyAddr,
            sellAddr
        );
        address[] memory paths = getPaths(
            address(_buyAddr),
            address(_sellAddr)
        );

        if (sellAmt == uint256(-1)) {
            sellAmt = sellAddr == ethAddr
                ? address(this).balance
                : _sellAddr.balanceOf(address(this));
        }

        uint256 _slippageAmt = convert18ToDec(
            _buyAddr.decimals(),
            wmul(unitAmt, convertTo18(_sellAddr.decimals(), sellAmt))
        );

        checkPair(paths);
        uint256 _expectedAmt = getExpectedBuyAmt(paths, sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        approve(_sellAddr, address(router), sellAmt);

        router.swapExactTokensForTokens(
            sellAmt,
            _expectedAmt,
            paths,
            address(this),
            block.timestamp + 1
        );
    }
}

contract ConnectV2UniswapV2 is UniswapResolver {
    string public constant name = "UniswapV2";
}
