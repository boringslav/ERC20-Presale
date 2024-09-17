// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {VestingModule} from "../src/VestingModule.sol";
import {LockupLinear} from "sablier/v2-core/src/types/DataTypes.sol";
import {Lockup} from "sablier/v2-core/src/types/DataTypes.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {Base} from "./Base.t.sol";

import {IERC20} from "@openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract VestingModuleTest is Base {
    function testCreateStream() external {
        vm.startBroadcast(TOKEN_OFFERER);
        IERC20(address(s_erc20Mock)).approve(address(s_vestingModule), 100);
        uint256 streamId = s_vestingModule.createStream(100, address(s_erc20Mock), 100 days, USER1);
        vm.stopBroadcast();

        LockupLinear.StreamLL memory stream = s_vestingModule.getStream(streamId);
        Lockup.Amounts memory amounts = stream.amounts;
        assertEq(stream.recipient, USER1);
        assertEq(amounts.deposited, 100);
        assertEq(amounts.withdrawn, 0);
        assertEq(amounts.refunded, 0);
        assertEq(stream.cliffTime, 0);
        assertEq(stream.endTime, block.timestamp + 100 days);
        assertEq(stream.isCancelable, false);
        assertEq(stream.isDepleted, false);
        assertEq(stream.isStream, true);
        assertEq(stream.isTransferable, true);
    }

    function testWithdrawFromStream() external {
        vm.startBroadcast(TOKEN_OFFERER);
        IERC20(address(s_erc20Mock)).approve(address(s_vestingModule), 100);
        uint256 streamId = s_vestingModule.createStream(100, address(s_erc20Mock), 100 days, USER1);
        vm.stopBroadcast();

        skip(100 days);
        vm.broadcast(USER1);
        s_vestingModule.withdraw(streamId);

        LockupLinear.StreamLL memory stream = s_vestingModule.getStream(streamId);
        Lockup.Amounts memory amounts = stream.amounts;
        assertEq(amounts.withdrawn, 100);
        assertEq(IERC20(address(s_erc20Mock)).balanceOf(USER1), 100);
    }
}
