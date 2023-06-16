// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract ExecuteManager {
    error TransactionExecutionFailed(bytes);

    function executeTransaction(
        address _to,
        uint256 _value,
        uint256 _gas,
        bytes memory _data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = _to.call{
            value: _value,
            gas: _gas
        }(_data);

        if (!success) {
            if (returnData.length > 0) {
                revert TransactionExecutionFailed(returnData);
            }

            revert TransactionExecutionFailed("0x");
        }

        return returnData;
    }
}
