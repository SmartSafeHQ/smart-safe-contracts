// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title This contract is used to ensure certain functions can be called only Smart Safe.
 * @author Ricardo Passos - @ricardo-passos
 */
contract SelfAuthorized {
    error CallerIsNotAuthorized();

    /**
     * @dev
     * Functions like `addNewOwner`, `removeOwner` and `changeThreshold` are external
     * but can't be directly called because they use this modifier. Instead, they can 
     * only be called via `createTransactionProposal`.
     */
    function authorized() internal view {
        if (msg.sender != address(this)) revert CallerIsNotAuthorized();
    }
}
