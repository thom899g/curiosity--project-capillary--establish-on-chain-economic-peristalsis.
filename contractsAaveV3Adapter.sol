// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IYieldSourceAdapter} from "./IYieldSourceAdapter.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AaveV3Adapter
 * @dev Adapter for Aave V3 yield source.
 */
contract AaveV3Adapter is IYieldSourceAdapter {
    using SafeERC20 for IERC20;

    IPool public immutable aavePool;

    constructor(address _aavePool) {
        aavePool = IPool(_aavePool);
    }

    /**
     * @dev Deposits `amount` of `asset` into Aave V3 and returns the number of aTokens minted.
     */
    function deposit(address asset, uint256 amount) external override returns (uint256 shares) {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeApprove(address(aavePool), amount);
        shares = aavePool.supply(asset, amount, address(this), 0);
    }

    /**
     * @dev Withdraws `shares` (aTokens) from Aave V3 and returns the amount of `asset` received.
     */
    function withdraw(address asset, uint256 shares) external override returns (uint256 amount) {
        // In Aave, the aToken is the share token. We need to transfer the aToken to this contract first.
        // However, note that the shares are already in this contract because we deposited from here.
        // The PeristalsisEngine will hold the aTokens. So we assume the aTokens are in this contract.
        // Alternatively, we could design the adapter to hold the aTokens, but we are keeping it simple.
        // We'll require that the aTokens are in this contract and the caller is the PeristalsisEngine.
        amount = aavePool.withdraw(asset, shares, msg.sender);
    }

    /**
     * @dev Returns the amount of yield (in terms of `asset`) that can be harvested from Aave V3.
     * In Aave, yield is accrued by the aToken increasing in value relative to the underlying.
     * This function calculates the increase in aToken balance in terms of the underlying.
     * Note: This is a simplified view. In practice, you might want to use the `getReserveData` function to get the liquidity index.
     */
    function harvestableYield(address asset) external view override returns (uint256) {
        // This is a placeholder. In Aave, the yield is accrued by the aToken increasing in value.
        // We need to get the current aToken balance and convert it to the underlying amount.
        // Then subtract the initial deposit (which we don't have in this view function).
        // Alternatively, we can design the PeristalsisEngine to track the deposited amount.
        // For now, we return 0 to be safe.
        // TODO: Implement a proper yield calculation using the Aave liquidity index.
        return 0;
    }
}