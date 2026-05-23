// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookFee} from "../src/HookFee.sol";

contract DeployHookFee is Script {

    address constant POOL_MANAGER     = 0x000000000004444c5dc75cB358380D2e3dE08A90;
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address constant FEE_RECIPIENT    = 0x3a22a82aE40e0a269D1B5B2BD322b8762E438ccB;

    address constant OWNER            = 0x966C117989EFE1d11Ba1A39d31C215fa851878E7;

    function run() external {

        uint160 flags = uint160(
            Hooks.AFTER_SWAP_FLAG |
            Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        );

        bytes memory initCode = abi.encodePacked(
            type(HookFee).creationCode,
            abi.encode(POOL_MANAGER, FEE_RECIPIENT, OWNER)
        );
        bytes32 bytecodeHash = keccak256(initCode);

        console.log("Mining... target: last 14 bits == 0x0044");

        address hookAddr;
        bytes32 salt;
        bool found;

        for (uint256 i = 0; i < 5_000_000; i++) {
            salt = bytes32(i);
            hookAddr = address(uint160(uint256(keccak256(abi.encodePacked(
                bytes1(0xff),
                CREATE2_DEPLOYER,
                salt,
                bytecodeHash
            )))));
            uint160 bottom14 = uint160(hookAddr) & 0x3FFF;
            if (bottom14 == flags) {
                console.log("Found at iteration:", i);
                console.log("Hook address:", hookAddr);
                found = true;
                break;
            }
        }

        require(found, "No valid salt found");

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        (bool ok,) = CREATE2_DEPLOYER.call(abi.encodePacked(salt, initCode));
        require(ok, "Deploy failed");
        require(hookAddr.code.length > 0, "Nothing at address");
        vm.stopBroadcast();

        console.log("Deployed at:", hookAddr);
        console.logBytes32(salt);

        uint160 bottom14 = uint160(hookAddr) & 0x3FFF;
        console.log("Bottom 14 bits:");
        console.logBytes32(bytes32(uint256(bottom14)));
        require(bottom14 == flags, "MISMATCH do not use");
        console.log("VERIFIED: ends in 0x0044");
    }
}