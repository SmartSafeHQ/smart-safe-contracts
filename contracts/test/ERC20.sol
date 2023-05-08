// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ERC20 {
    function transfer(address to, uint256 amount)
        external
        pure
        returns (string memory)
    {
        return "called";
    }
}
