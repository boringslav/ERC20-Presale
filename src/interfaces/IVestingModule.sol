// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IVestingModule {
    error VestingModule__CallerNotOwner();

    event StreamCreated(address recipient, uint256 streamId, uint256 amountToVest, address token, uint40 duration);

    /**
     * @param amountToVest The total amount of tokens to be streamed.
     * @param token The address of the token to be streamed.
     * @return streamId The ID of the created stream.
     */
    function createStream(uint256 amountToVest, address token, uint40 duration, address recipient)
        external
        returns (uint256 streamId);
}
