// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IModulesManager {
    function executeTransactionFromModule(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external returns (bytes memory);
}
