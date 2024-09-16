// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/**
 * @title ITreasury
 * @author  Boringslav
 * @notice  Interface for the Treasury contract
 */
interface ITreasury {
    error Treasury__CallerNotOwnerOfTreasury();
    error Treasury__PresaleAlreadyCreatedError();
    error Treasury__PresaleStartError();
    error Treasury__CallerNotOwner();
    error Treasury__PresaleCannotBeCancelled();
    error Treasury__PresaleNotActive();
    error Treasury__TokenLimitReached();
    error Treasury__InsufficientFunds();
    error Treasury__PresaleDurationTooShort();
    error Treasury__PresaleNotCompleted();
    error Treasury__PresaleNotVesting();
    error Treasury__NoTokensToVest();

    event PresaleCreated(address indexed token, uint256 indexed price);
    event PresaleStarted(address indexed token, uint256 indexed endTime);
    event PresaleCancelled(address indexed token);
    event PresaleTokenBought(address indexed token, uint256 indexed amount, address indexed buyer);
    event PresaleTokenSold(address indexed token, uint256 indexed amount, address indexed seller);
    event TokensVested(address indexed token, address indexed recipient, uint256 indexed streamId);

    /**
     * @notice Struct for presale token
     * @param token Address of the token
     * @param price Price of 1 token
     * @param amount Total amount of tokens available for sale
     * @param soldAmount Amount of tokens already sold
     */
    struct TokenInfo {
        address token;
        uint256 price;
        uint256 amount;
        uint256 soldAmount;
    }

    /**
     *
     * @param amountToRaise - Amount of native token to raise
     * @param raisedAmount - Amount of native token raised
     * @param startTime - Start time of the presale
     * @param endTime - End time of the presale
     * @param status - Status of the presale
     * @param owner - Owner of the presale
     * @param vestingDuration - Duration of the vesting in seconds
     */
    struct PresaleInfo {
        uint256 amountToRaise;
        uint256 raisedAmount;
        TokenInfo tokenInfo;
        uint256 startTime;
        uint256 endTime;
        uint40 vestingDuration;
        PresaleStatus status;
        address owner;
    }

    /**
     *
     * @param PENDING - Presale is pending (created but not started)
     * @param ACTIVE - Presale is active (started)
     * @param COMPLETED - Presale is completed (ended)
     * @param VESTING - Presale is in vesting (tokens are vested)
     */
    enum PresaleStatus {
        PENDING,
        ACTIVE,
        COMPLETED,
        VESTING
    }

    /**
     * @param _token - Address of the presale token
     * @param _amount -  Amount of tokens available for sale
     * @param _amountToRaise - Amount of native token to raise
     * @notice Create a presale for an ERC20 token with the goal of raising a certain amount of native tokens
     * @dev The tokens stay locked in the treasury until the presale ends
     */
    function createErc20Presale(address _token, uint256 _amount, uint256 _amountToRaise) external;

    /**
     * @param _duration - Duration of the presale in seconds
     * @notice Start the presale for the ERC20 token
     */
    function startErc20Presale(address token, uint256 _duration) external;

    /**
     * @param token - Address of the token
     * @notice Cancel the presale for the ERC20 token
     */
    function cancelErc20Presale(address token) external;

    /**
     * @param token - Address of the token
     * @param amount - Amount of tokens to buy
     * @notice Buy tokens in the presale
     */
    function buyErc20Presale(address token, uint256 amount) external payable;

    /**
     *
     * @param token - Address of the token
     * @param amount - Amount of tokens to sell
     * @notice Sell tokens in the presale
     * @dev When users sell tokens that they have bought there is a 5% fee
     */
    function sellErc20Presale(address token, uint256 amount) external;

    /**
     * @param token - Address of the token
     * @param duration - Duration of the vesting in seconds
     * @notice Presale Token team can call this function to set the vesting duration and start the vesting
     */
    function startVesting(address token, uint40 duration) external;

    /**
     * @param token Address of the presale token
     * @notice Users call this to put their tokens for vesting in Sablier
     */
    function vestTokens(address token) external returns (uint256 streamId);

    /**
     * @param vestingModule - Address of the vesting module
     * @notice Set the vesting module (Only callable by the owner of the treasury)
     */
    function setVestingModule(address vestingModule) external;

    /**
     * @param _tokenAmount -  Amount of tokens available for sale
     * @param _amountToRaise - Amount of native token to raise
     * @notice Preview the price of the token in the presale based on the token supply and the amount to raise
     */
    function previewPresalePrice(uint256 _tokenAmount, uint256 _amountToRaise)
        external
        view
        returns (uint256 tokenPrice);

    /**
     * @notice Get the presale information for a token
     * @param token - Address of the token
     */
    function getPresaleInfo(address token) external view returns (PresaleInfo memory);
    /**
     * @notice Get the token information
     * @param token - Address of the token
     */
    function getTokenInfo(address token) external view returns (TokenInfo memory);

    /**
     *  @notice Get the amount of tokens purchased by a user
     *  @param user - Address of the user
     *  @param token - Address of the presale token
     */
    function getUserPurchasedTokens(address user, address token) external view returns (uint256);
}
