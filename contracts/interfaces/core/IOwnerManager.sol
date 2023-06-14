// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOwnerManager {
    function totalOwners() external view returns (uint8);

    function threshold() external view returns (uint8);
}