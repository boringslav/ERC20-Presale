// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IFactory {
    function deployTreasury(bytes32 salt) external;
    function deployVestingModule(bytes32 salt, address lockupLinear) external;
}
