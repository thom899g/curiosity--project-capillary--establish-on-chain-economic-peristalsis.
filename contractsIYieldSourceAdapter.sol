// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IYieldSourceAdapter
 * @dev Abstract interface for yield source adapters.
 *      This interface allows the PeristalsisEngine to interact with any yield source.
 */
interface IYieldSourceAdapter {
    /**
     * @dev Deposits `amount` of `asset` into the yield source and returns the number of shares minted.
     * @param asset The address of the asset to deposit (must be the underlying asset of the yield source).
     * @param amount The amount of `asset` to deposit.
     * @return shares The number of shares minted in the yield source.
     */
    function deposit(address asset, uint256 amount) external returns (uint256 shares);

    /**
     * @dev Withdraws `shares` from the yield source and returns the amount of `asset` received.
     * @param asset The address of the asset to withdraw (must be the underlying asset of the yield source).
     * @param shares The number of shares to burn.
     * @return amount The amount of `asset` received.
     */
    function withdraw(address asset, uint256 shares) external returns (uint256 amount);

    /**
     * @dev Returns the amount of yield (in terms of `asset`) that can be harvested from the yield source.
     * @param asset The address of the asset to check (must be the underlying asset of the yield source).
     * @return The amount of `asset` that can be harvested.
     */
    function harvestableYield(address asset) external view returns (uint256);
}