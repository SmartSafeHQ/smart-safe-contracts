// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FallbackManager {
    event SafeReceived(address indexed sender, uint256 value);

    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}
