// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract ExecuteManager {
    error TransactionExecutionFailed(bytes);

    function executeTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        (bool success, bytes memory data) = _to.call{value: _value}(_data);

        if (!success && data.length > 0) {
            revert TransactionExecutionFailed(_data);
        }
    }
}
