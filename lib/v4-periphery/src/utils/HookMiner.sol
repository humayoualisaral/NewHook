// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.21;

library HookMiner {
    // Hook flags live in the BOTTOM 14 bits of the address
    uint160 constant FLAG_MASK = 0x3FFF;

    function find(
        address deployer,
        uint160 flags,
        bytes memory creationCode,
        bytes memory constructorArgs
    ) external view returns (address, bytes32) {
        bytes memory creationCodeWithArgs = abi.encodePacked(creationCode, constructorArgs);
        for (uint256 i = 0; i < 160000; i++) {
            bytes32 salt = bytes32(i);
            address hookAddress = computeAddress(deployer, salt, creationCodeWithArgs);
            if (uint160(hookAddress) & FLAG_MASK == flags & FLAG_MASK) {
                return (hookAddress, salt);
            }
        }
        revert("HookMiner: could not find salt");
    }

    function computeAddress(address deployer, bytes32 salt, bytes memory creationCode)
        public pure returns (address)
    {
        return address(uint160(uint256(keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(creationCode))
        ))));
    }
}
