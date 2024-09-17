// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {LockupLinear} from "sablier/v2-core/src/types/DataTypes.sol";

interface IVestingModule {
    event StreamCreated(address recipient, uint256 streamId, uint256 amountToVest, address token, uint40 duration);
    event StreamTransferred(address oldRecipient, address newRecipient, uint256 streamId);

    /**
     * @param amountToVest The total amount of tokens to be streamed.
     * @param token The address of the token to be streamed.
     * @return streamId The ID of the created stream.
     */
    function createStream(uint256 amountToVest, address token, uint40 duration, address recipient)
        external
        returns (uint256 streamId);

    /**
     * @notice Withdraws the available amount from the stream.
     * @param _streamId The ID of the stream to withdraw from.
     */
    function withdraw(uint256 _streamId) external;

    // GETTERS
    function getAmountAvailableToWithdraw(uint256 _streamId) external view returns (uint128);

    function getStream(uint256 _streamId) external view returns (LockupLinear.StreamLL memory);
}
