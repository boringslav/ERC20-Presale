// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Treasury} from "./Treasury.sol";
import {VestingModule} from "./VestingModule.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {console2} from "forge-std/console2.sol";

contract Factory is IFactory {
    error Factory__OnlyOwner();

    event TreasuryDeployed(address indexed treasury);
    event VestingModuleDeployed(address indexed bootstrapModule);

    address public s_owner;
    address public s_treasury;
    address public s_vestingModule;

    constructor() {
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert Factory__OnlyOwner();
        _;
    }

    function deployVestingModule(bytes32 _salt, address _lockupLinear) external onlyOwner {
        s_vestingModule = address(new VestingModule{salt: _salt}(_lockupLinear, s_owner));
        emit VestingModuleDeployed(s_vestingModule);
    }

    function deployTreasury(bytes32 _salt) external onlyOwner {
        s_treasury = address(new Treasury{salt: _salt}(s_owner));
        emit TreasuryDeployed(s_treasury);
    }
}
