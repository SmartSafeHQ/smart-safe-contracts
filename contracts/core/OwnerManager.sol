// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SelfAuthorized} from "../utils/SelfAuthorized.sol";

contract OwnerManager is SelfAuthorized {
    error NotAnOwner();
    error InvalidAddress();
    error OutOfBoundsThreshold();
    error DuplicatedAddress(address);

    event OwnerAdded(address);
    event OwnerRemoved(address);
    event ThresholdChanged(uint8 from, uint8 to);

    uint8 public threshold = 1;

    address private constant LINKED_LIST = address(0x1);

    uint8 public totalOwners;
    mapping(address => address) private owners;

    function isValidAddress(address _address) private view {
        if (
            _address == address(0) ||
            _address == address(this) ||
            _address == LINKED_LIST ||
            owners[_address] != address(0)
        ) {
            revert InvalidAddress();
        }
    }

    function setupOwners(address[] memory _owners, uint8 _threshold) internal {
        if (_threshold > _owners.length) {
            revert OutOfBoundsThreshold();
        }

        address currentOwner = LINKED_LIST;
        for (uint8 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            isValidAddress(owner);

            if (currentOwner == owner) revert DuplicatedAddress(owner);

            owners[currentOwner] = owner;
            currentOwner = owner;
        }

        owners[currentOwner] = LINKED_LIST;
        totalOwners = uint8(_owners.length);
        threshold = _threshold;
    }

    function addNewOwner(
        address _newOwner,
        uint8 _newThreshold
    ) public authorized {
        isValidAddress(_newOwner);

        owners[_newOwner] = owners[LINKED_LIST];
        owners[LINKED_LIST] = _newOwner;
        totalOwners++;

        emit OwnerAdded(_newOwner);

        if (_newThreshold != threshold) changeThreshold(_newThreshold);
    }

    function removeOwner(address _prevOwner, address _owner) public authorized {
        require(owners[_owner] != address(0));

        owners[_prevOwner] = owners[_owner];
        owners[_owner] = address(0);
        threshold--;
        totalOwners--;

        emit OwnerRemoved(_owner);
    }

    function changeThreshold(uint8 _newThreshold) public authorized {
        if (_newThreshold < 1 || _newThreshold > totalOwners) {
            revert OutOfBoundsThreshold();
        }

        uint8 prevThreshold = threshold;
        threshold = _newThreshold;

        emit ThresholdChanged(prevThreshold, _newThreshold);
    }

    function getOwners() public view returns (address[] memory) {
        address[] memory listOfOwners = new address[](totalOwners);

        uint256 index = 0;
        address currentOwner = owners[LINKED_LIST];
        while (currentOwner != LINKED_LIST) {
            listOfOwners[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }

        return listOfOwners;
    }

    function isSafeOwner(address _owner) internal view {
        if (_owner == LINKED_LIST || owners[_owner] == address(0)) {
            revert NotAnOwner();
        }
    }
}
