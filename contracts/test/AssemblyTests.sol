// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AssemblyTests {
    function test()
        external
        pure
        returns (
            bytes1,
            bytes1,
            bytes32,
            bytes32
        )
    {
        bytes1 value1;
        bytes1 value2;
        bytes32 ptr1;
        bytes32 ptr2;

        assembly {
            let freeMemoryPointer1 := mload(0x40)
            ptr1 := freeMemoryPointer1

            mstore8(freeMemoryPointer1, 0x20)

            let freeMemoryPointer2 := add(freeMemoryPointer1, 8)
            ptr2 := freeMemoryPointer2

            mstore(0x40, freeMemoryPointer2)

            mstore8(freeMemoryPointer2, 0xff)

            mstore(0x40, add(freeMemoryPointer2, 8))

            value1 := mload(freeMemoryPointer1)
            value2 := mload(freeMemoryPointer2)
        }

        return (value1, value2, ptr1, ptr2);
    }
}
