// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SelfAuthorized} from "../utils/SelfAuthorized.sol";

/**
 * @title This contract manages users who owns a Smart Safe.
 * @author Ricardo Passos - @ricardo-passos
 */
contract OwnerManager is SelfAuthorized {
    using EnumerableSet for EnumerableSet.AddressSet;

    error NotAnOwner();
    error InvalidAddress();
    error OutOfBoundsThreshold();
    error DuplicatedAddress(address);

    event OwnerAdded(address);
    event OwnerRemoved(address);
    event ThresholdChanged(uint8 from, uint8 to);

    uint8 public threshold = 1;

    uint8 public totalOwners;

    EnumerableSet.AddressSet private owners;

    function isValidAddress(address _address) private view {
        if (
            _address == address(0) ||
            _address == address(this) ||
            owners.contains(_address)
        ) {
            revert InvalidAddress();
        }
    }

    function _setupOwners(address[] memory _owners, uint8 _threshold) internal {
        for (uint8 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            isValidAddress(owner);

            owners.add(owner);
        }

        totalOwners = uint8(_owners.length);
        threshold = _threshold;
    }

    function addNewOwner(address _newOwner, uint8 _newThreshold) public {
        SelfAuthorized.authorized();

        isValidAddress(_newOwner);

        owners.add(_newOwner);
        totalOwners++;

        emit OwnerAdded(_newOwner);

        if (_newThreshold != threshold) changeThreshold(_newThreshold);
    }

    function removeOwner(address _owner) public {
        SelfAuthorized.authorized();

        owners.remove(_owner);

        threshold--;
        totalOwners--;

        emit OwnerRemoved(_owner);
    }

    function changeThreshold(uint8 _newThreshold) public {
        SelfAuthorized.authorized();

        if (_newThreshold < 1 || _newThreshold > totalOwners) {
            revert OutOfBoundsThreshold();
        }

        uint8 prevThreshold = threshold;
        threshold = _newThreshold;

        emit ThresholdChanged(prevThreshold, _newThreshold);
    }

    function getOwners() public view returns (address[] memory) {
        return owners.values();
    }

    function isSafeOwner(address _owner) internal view returns (bool) {
        if (!owners.contains(_owner)) {
            return false;
        }

        return true;
    }
}
