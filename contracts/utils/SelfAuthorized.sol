// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
