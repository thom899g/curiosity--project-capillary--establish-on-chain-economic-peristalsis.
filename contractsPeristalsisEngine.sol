// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IYieldSourceAdapter} from "./IYieldSourceAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title PeristalsisEngine
 * @dev The core contract for the autonomous yield cycling system.
 *      It is upgradeable and uses a pluggable yield source adapter.
 */
contract PeristalsisEngine is Initializable, OwnableUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    IYieldSourceAdapter public yieldSourceAdapter;
    uint256 public totalCycles;
    uint256 public lastCycleTimestamp;
    uint256 public minProfitThreshold; // in wei (the asset's smallest unit)

    // Bounty configuration
    struct BountyConfig {
        uint256 baseBounty;
        uint256 gasMultiplier; // in basis points (e.g., 12000 for 1.2x)
    }
    BountyConfig public bountyConfig;

    // Constants
    uint256 public constant MIN_CYCLE_INTERVAL = 1 hours;
    uint256 public constant MAX_BOUNTY_PERCENT = 10; // 10%

    // Events
    event CycleExecuted(
        uint256 indexed cycleId,
        uint256 timestamp,
        uint256 yieldHarvested,
        uint256 bountyPaid,
        address keeper
    );
    event YieldSourceUpdated(address indexed oldAdapter, address indexed newAdapter);
    event BountyConfigUpdated(uint256 baseBounty, uint256 gasMultiplier);

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _yieldSourceAdapter The address of the yield source adapter.
     * @param _governance The address of the governance (owner).
     * @param _minProfitThreshold The minimum profit (in wei) required to execute a cycle.
     */
    function initialize(
        address _yieldSourceAdapter,
        address _governance,
        uint256 _minProfitThreshold
    ) public initializer {
        __Ownable_init(_governance);
        yieldSourceAdapter = IYieldSourceAdapter(_yieldSourceAdapter);
        minProfitThreshold = _minProfitThreshold;
        // Initialize bounty config with default values
        bountyConfig.baseBounty = 0.001 ether; // 0.001 MATIC
        bountyConfig.gasMultiplier = 12000; // 1.2x
    }

    /**
     * @dev Executes a cycle if conditions are met. Permissionless.
     * @param _executionData Data to pass to the yield source adapter (if needed).
     */
    function cycle(bytes calldata _executionData) external nonReentrant {
        require(block.timestamp - lastCycleTimestamp >= MIN_CYCLE_INTERVAL, "PeristalsisEngine: too soon");
        uint256 harvestable = yieldSourceAdapter.harvestableYield(address(0)); // We need to specify the asset. How?
        // We need to know the asset we are cycling. For simplicity, we assume it's set at initialization.
        // Alternatively, we can store the asset address in the contract.
        // Let's assume we are using USDC and we set it in the constructor. We'll need to add an `asset` state variable.
        // We'll skip this for now and note it as a TODO.
        require(harvestable >= minProfitThreshold, "PeristalsisEngine: insufficient yield");

        // Calculate bounty
        uint256 bounty = calculateBounty();
        require(bounty <= harvestable * MAX_BOUNTY_PERCENT / 100, "PeristalsisEngine: bounty too high");

        // Harvest yield (how? we need to interact with the adapter to withdraw the yield)
        // We don't have a function to harvest yield in the adapter. We need to design it.
        // The adapter should have a function to harvest yield and return the amount.
        // Alternatively, we can redesign the cycle to:
        // 1. Withdraw the entire amount (principal + yield) from the yield source.
        // 2. Calculate the yield as (total withdrawn - principal).
        // 3. Take the bounty from the yield.
        // 4. Reinvest the principal and the remaining yield.
        // We need to track the principal. Let's add a state variable for totalDeposited.

        // For now, we leave the logic incomplete and note the required changes.

        // TODO: Implement the cycle logic with the above steps.

        // Update state
        totalCycles++;
        lastCycleTimestamp = block.timestamp;

        // Emit event
        emit CycleExecuted(totalCycles, block.timestamp, harvestable, bounty, msg.sender);
    }

    /**
     * @dev Calculates the bounty for the current cycle based on gas price and bounty config.
     */
    function calculateBounty() public view returns (uint256) {
        // We don't have access to the current transaction's gas price in the contract.
        // We can use `tx.gasprice` but that is only available in the transaction.
        // We'll use `tx.gasprice` in the `cycle` function, but here we can't.
        // We'll leave it as a placeholder.
        // Alternatively, we can remove this function and calculate in `cycle`.
        // We'll do that in the `cycle` function.
        return 0;
    }

    /**
     * @dev Updates the yield source adapter. Only callable by governance.
     * @param _newAdapter The address of the new yield source adapter.
     */
    function updateYieldSource(address _newAdapter) external onlyOwner {
        require(_newAdapter != address(0), "PeristalsisEngine: zero address");
        address oldAdapter = address(yieldSourceAdapter);
        yieldSourceAdapter = IYieldSourceAdapter(_newAdapter);
        emit YieldSourceUpdated(oldAdapter, _newAdapter);
    }

    /**
     * @dev Updates the bounty configuration. Only callable by governance.
     * @param _baseBounty The base bounty (in wei).
     * @param _gasMultiplier The gas multiplier (in basis points).
     */
    function setBountyConfig(uint256 _baseBounty, uint256 _gasMultiplier) external onlyOwner {
        bountyConfig.baseBounty = _baseBounty;
        bountyConfig.gasMultiplier = _gasMultiplier;
        emit BountyConfigUpdated(_baseBounty, _gasMultiplier);
    }

    /**
     * @dev Pauses the contract. Only callable by governance.
     */
    function pause() external onlyOwner {
        // TODO: Implement pausing mechanism (like a state variable) that the `cycle` function checks.
    }

    /**
     * @dev Sets the minimum profit threshold. Only callable by governance.
     */
    function setMinProfitThreshold(uint256 _minProfitThreshold) external onlyOwner {
        minProfitThreshold = _minProfitThreshold;
    }

    // TODO: Add a function to deposit initial capital and withdraw capital (if needed).
    // TODO: Add a function to track the principal (totalDeposited) and yield.
}