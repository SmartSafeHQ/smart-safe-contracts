// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ExecuteManager} from "../core/ExecuteManager.sol";

contract BatchTransactions is ReentrancyGuard, ExecuteManager {
    error InvalidPayload();

    function executeBatchTransactions(
        address[] calldata _targets,
        uint256[] calldata _values,
        uint256[] calldata _gas,
        bytes[] calldata _data
    ) external nonReentrant {
        if (
            _data.length != _targets.length ||
            _values.length != _targets.length ||
            _gas.length != _targets.length
        ) {
            revert InvalidPayload();
        }

        for (uint64 i = 0; i < _targets.length; i++) {
            ExecuteManager.executeTransaction(
                _targets[i],
                _values[i],
                _gas[i],
                _data[i]
            );
        }
    }
}
