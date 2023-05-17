// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title This contract only manages the network native tokens sent to a Smart Safe.
 * @author Ricardo Passos - @ricardo-passos
 */
contract FallbackManager {
    event SafeReceived(address indexed sender, uint256 value);

    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}
