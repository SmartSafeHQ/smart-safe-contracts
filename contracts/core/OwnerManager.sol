// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract OwnerManager {
    error InvalidThreshold();
    error InvalidAddress();
    error NotAnOwner();

    uint8 internal threshold = 1;

    address internal constant LINKED_LIST = address(0x1);

    uint8 public totalOwners;
    mapping(address => address) internal owners;

    function setupOwners(address[] memory _owners, uint8 _threshold) internal {
        if (_threshold != _owners.length) {
            revert InvalidThreshold();
        }

        address currentOwner = LINKED_LIST;
        for (uint8 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (
                owner == address(0) ||
                owner == address(this) ||
                owner == LINKED_LIST ||
                owners[owner] != address(0)
            ) {
                revert InvalidAddress();
            }

            owners[currentOwner] = owner;
            currentOwner = owner;
        }

        owners[currentOwner] = LINKED_LIST;
        totalOwners = uint8(_owners.length);
        threshold = _threshold;
    }

    function isSafeOwner(address _owner) internal view {
        if (_owner == LINKED_LIST || owners[_owner] == address(0)) {
            revert NotAnOwner();
        }
    }
}
