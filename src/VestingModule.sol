// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IVestingModule} from "./interfaces/IVestingModule.sol";

import {ISablierV2LockupLinear} from "sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {Broker, LockupLinear} from "sablier/v2-core/src/types/DataTypes.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ud60x18} from "@prb/math/src/UD60x18.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract VestingModule is IVestingModule {
    ISablierV2LockupLinear public immutable LOCKUP_LINEAR;
    address public s_owner;

    constructor(address _lockupLinear, address _owner) {
        LOCKUP_LINEAR = ISablierV2LockupLinear(_lockupLinear);
        s_owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert VestingModule__CallerNotOwner();
        _;
    }

    /**
     * @inheritdoc IVestingModule
     */
    function createStream(uint256 _amountToVest, address _token, uint40 _duration, address _recipient)
        external
        returns (uint256 streamId)
    {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        SafeTransferLib.safeTransferFrom(_token, msg.sender, address(this), _amountToVest);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        uint128 amountToVest = uint128(balanceAfter) - uint128(balanceBefore);

        IERC20(_token).approve(address(LOCKUP_LINEAR), amountToVest);

        LockupLinear.CreateWithDurations memory params = LockupLinear.CreateWithDurations({
            sender: address(this),
            recipient: _recipient,
            totalAmount: amountToVest,
            asset: IERC20(_token),
            cancelable: false,
            transferable: true,
            durations: LockupLinear.Durations({cliff: 0, total: _duration}),
            broker: Broker(address(0), ud60x18(0))
        });

        streamId = LOCKUP_LINEAR.createWithDurations(params);
        emit StreamCreated(_recipient, streamId, _amountToVest, _token, _duration);
    }
}
