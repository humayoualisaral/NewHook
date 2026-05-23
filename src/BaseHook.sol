// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";


abstract contract BaseHook is IHooks {
    error NotPoolManager();
    error HookNotImplemented();

    IPoolManager public immutable poolManager;

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
        Hooks.validateHookPermissions(IHooks(address(this)), getHookPermissions());
    }

    function getHookPermissions()
        public
        pure
        virtual
        returns (Hooks.Permissions memory);

    function beforeInitialize(address, PoolKey calldata, uint160)
        external virtual onlyPoolManager returns (bytes4) { revert HookNotImplemented(); }

    function afterInitialize(address, PoolKey calldata, uint160, int24)
        external virtual onlyPoolManager returns (bytes4) { revert HookNotImplemented(); }

    function beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external virtual onlyPoolManager returns (bytes4) { revert HookNotImplemented(); }

    function afterAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, BalanceDelta, BalanceDelta, bytes calldata)
        external virtual onlyPoolManager returns (bytes4, BalanceDelta) { revert HookNotImplemented(); }

    function beforeRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata)
        external virtual onlyPoolManager returns (bytes4) { revert HookNotImplemented(); }

    function afterRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, BalanceDelta, BalanceDelta, bytes calldata)
        external virtual onlyPoolManager returns (bytes4, BalanceDelta) { revert HookNotImplemented(); }

    function beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external virtual onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24)
    {
        return _beforeSwap(sender, key, params, hookData);
    }

    function afterSwap(address sender, PoolKey calldata key, SwapParams calldata params, BalanceDelta delta, bytes calldata hookData)
        external virtual onlyPoolManager returns (bytes4, int128)
    {
        return _afterSwap(sender, key, params, delta, hookData);
    }

    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external virtual onlyPoolManager returns (bytes4) { revert HookNotImplemented(); }

    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external virtual onlyPoolManager returns (bytes4) { revert HookNotImplemented(); }



    function _beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        internal virtual returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    function _afterSwap(address, PoolKey calldata, SwapParams calldata, BalanceDelta, bytes calldata)
        internal virtual returns (bytes4, int128)
    {
        revert HookNotImplemented();
    }
}
