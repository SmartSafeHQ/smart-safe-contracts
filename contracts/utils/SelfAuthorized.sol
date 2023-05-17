// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title This contract is used to ensure certain functions can be called only Smart Safe.
 * @author Ricardo Passos - @ricardo-passos
 * @dev
 * Functions like `addNewOwner`, `removeOwner` and `changeThreshold` should not
 * be directly called. They must be called via `createTransactionProposal`. This contract
 * ensure this by requiring these functions are called by Smart Safe itself.
 */
contract SelfAuthorized {
    error CallerIsNotAuthorized();

    function _authorized() private view {
        if (msg.sender != address(this)) revert CallerIsNotAuthorized();
    }

    modifier authorized() {
        _authorized();
        _;
    }
}
