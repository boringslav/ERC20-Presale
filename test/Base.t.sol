// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {ITreasury} from "../src/interfaces/ITreasury.sol";
import {IVestingModule} from "../src/interfaces/IVestingModule.sol";
import {VestingModule} from "../src/VestingModule.sol";

contract Base is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    address LOCKUP_LINEAR = 0x3962f6585946823440d274aD7C719B02b49DE51E;

    Factory public s_factory;

    ITreasury public s_treasury;
    IVestingModule public s_vestingModule;
    ERC20Mock public s_erc20Mock;

    bytes32 public s_treasurySalt = bytes32("TREASURY");
    bytes32 public s_vestingModuleSalt = bytes32("BOOTSTRAP_MODULE");

    address public DEPLOYER;
    address public TOKEN_OFFERER;
    address public USER1;
    address public USER2;

    function setUp() public {
        // Fork Mainnet
        vm.createSelectFork(MAINNET_RPC_URL, 20767360);

        // Create contract addresses
        DEPLOYER = makeAddr("DEPLOYER");
        TOKEN_OFFERER = makeAddr("TOKEN_OFFERER");
        USER1 = makeAddr("USER1");
        USER2 = makeAddr("USER2");

        vm.startBroadcast(DEPLOYER);
        s_factory = new Factory();
        // Deploy Treasury and BootstrapModule
        s_factory.deployTreasury(s_treasurySalt);
        s_treasury = ITreasury(s_factory.s_treasury());
        s_factory.deployVestingModule(s_vestingModuleSalt, LOCKUP_LINEAR);
        s_vestingModule = IVestingModule(s_factory.s_vestingModule());
        vm.stopBroadcast();

        // Deal Some $
        vm.deal(DEPLOYER, 100 ether);
        vm.deal(TOKEN_OFFERER, 100 ether);
        vm.deal(USER1, 1000 ether);

        vm.startBroadcast(TOKEN_OFFERER);
        s_erc20Mock = new ERC20Mock("TestToken", "TT");
        // Mint 100 tokens to TOKEN_OFFERER
        s_erc20Mock.mint(TOKEN_OFFERER, 100 ether);
        // Approve Treasury to spend 100 tokens from TOKEN_OFFERER
        s_erc20Mock.approve(address(s_treasury), 100 ether);
        vm.stopBroadcast();
    }

    function testFactoryOnlyOwner() public {
        vm.expectRevert(Factory.Factory__OnlyOwner.selector);
        s_factory.deployTreasury(s_treasurySalt);
        vm.expectRevert(Factory.Factory__OnlyOwner.selector);
        s_factory.deployVestingModule(s_vestingModuleSalt, LOCKUP_LINEAR);
    }
}
