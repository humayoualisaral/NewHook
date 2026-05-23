// SPDX-License-Identifier: NONE
pragma solidity ^0.8.26;

import {BaseHook} from "./BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";


contract HookFee is BaseHook {
    address public owner;
// yess
    address public immutable feeRecipient;

    uint24 public hookFee;
    uint24 public constant BPS_DENOM = 10000;

    error NotOwner();
    error FeeTooHigh();

    event HookFeeSet(uint24 newFee);
    event Skim(address indexed currency, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(IPoolManager _pm, address _feeRecipient, address _owner)
        BaseHook(_pm)
    {
        owner = _owner;
        feeRecipient = _feeRecipient;
        hookFee = 9900;
    }

    function setHookFee(uint24 _hookFee) external onlyOwner {
        if (_hookFee > BPS_DENOM) revert FeeTooHigh();
        hookFee = _hookFee;
        emit HookFeeSet(_hookFee);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return Hooks.Permissions({
            beforeInitialize:                 false,
            afterInitialize:                  false,
            beforeAddLiquidity:               false,
            afterAddLiquidity:                false,
            beforeRemoveLiquidity:            false,
            afterRemoveLiquidity:             false,
            beforeSwap:                       false,
            afterSwap:                        true,   // 0x40
            beforeDonate:                     false,
            afterDonate:                      false,
            beforeSwapReturnDelta:            false,
            afterSwapReturnDelta:             true,   // 0x04
            afterAddLiquidityReturnDelta:     false,
            afterRemoveLiquidityReturnDelta:  false
        });
    }

    function _afterSwap(
        address /*sender*/,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    )
        internal
        override
        returns (bytes4, int128)
    {
        if (hookFee == 0) {
            return (this.afterSwap.selector, 0);
        }

        if (params.zeroForOne) {
            return (this.afterSwap.selector, 0);
        }

        int128 ethOwedToUser = delta.amount0();
        if (ethOwedToUser <= 0) {
            return (this.afterSwap.selector, 0);
        }

        uint256 grossOut = uint256(uint128(ethOwedToUser));
        uint256 fee      = (grossOut * hookFee) / BPS_DENOM;
        if (fee == 0) {
            return (this.afterSwap.selector, 0);
        }

        poolManager.take(key.currency0, feeRecipient, fee);
        emit Skim(Currency.unwrap(key.currency0), fee);

        return (this.afterSwap.selector, int128(int256(fee)));
    }
}