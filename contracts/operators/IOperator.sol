// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/// @notice Performs operations on behalf of parties.
interface IOperator {
    /// @notice Executes an operation.
    /// @param operatorData Data to be used by the operator, known at the time
    ///                     operation was proposed.
    /// @param executionData Data to be used by the execution, known at the time
    ///                      operation was executed.
    function execute(bytes memory operatorData, bytes memory executionData) external payable;
}
