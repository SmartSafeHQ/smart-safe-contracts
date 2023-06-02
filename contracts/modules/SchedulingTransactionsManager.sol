// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISmartSafe} from "../interfaces/ISmartSafe.sol";

/**
 * @title This contract manages the scheduled transactions created by users.
 * @author Ricardo Passos - @ricardo-passos
 */
contract SchedulingTransactionsManager {
    ISmartSafe public immutable smartSafe;

    constructor(ISmartSafe _smartSafeAddress) {
        smartSafe = _smartSafeAddress;
    }

    function executeTransaction(uint64 _transactionNonce) external {
        smartSafe.executeTransaction(_transactionNonce);
    }
}
