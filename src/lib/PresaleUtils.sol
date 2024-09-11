// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

library PresaleUtils {
    error PresaleUtils__DivideByZeroError();

    /**
     * @param _amount -  Amount of tokens available for sale
     * @param _amountToRaise - Amount of native token to raise
     * @notice Calculate the price of the token in the presale based on the token supply and the amount to raise
     */
    function calculatePresalePrice(uint256 _amount, uint256 _amountToRaise)
        external
        pure
        returns (uint256 tokenPrice)
    {
        if (_amount == 0 || _amountToRaise == 0) {
            revert PresaleUtils__DivideByZeroError();
        }
        return (_amountToRaise * 1e18) / _amount;
    }
}
