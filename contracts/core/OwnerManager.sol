// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract OwnerManager {
    uint8 internal threshold = 1;

    address internal constant LINKED_LIST = address(0x1);

    uint8 public totalOwners;
    mapping(address => address) internal owners;

    function setupOwners(address[] memory _owners, uint8 _threshold) internal {
        require(
            _owners.length <= _threshold,
            "[OwnerManager#setupOwners]: owners length should be less than or equal to threshold."
        );

        address currentOwner = LINKED_LIST;
        for (uint8 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(
                owner != address(0) &&
                    owner != address(this) &&
                    owner != LINKED_LIST,
                "[OwnerManager#setupOwners]: invalid owner address."
            );
            require(
                owners[owner] == address(0),
                "[OwnerManager#setupOwners]: address already registered as owner."
            );

            owners[currentOwner] = owner;
            currentOwner = owner;
        }

        owners[currentOwner] = LINKED_LIST;
        totalOwners = uint8(_owners.length);
        threshold = _threshold;
    }

    function isSafeOwner(address _owner) internal view {
        require(
            _owner != LINKED_LIST && owners[_owner] != address(0),
            "[OwnerManager#isSafeOwner]: _owner is not a safe owner."
        );
    }
}
