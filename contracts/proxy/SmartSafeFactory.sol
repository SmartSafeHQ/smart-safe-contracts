// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SmartSafe} from "../core/SmartSafe.sol";

/**
 * @author Ricardo Passos - @ricardo-passos
 */
contract SmartSafeFactory {
    uint64 internal nonce = 0;

    error InvalidContractAddress();
    event Deployed(address indexed);

    function computeSalt(address _owner) private view returns (bytes32) {
        return keccak256(abi.encode(nonce, _owner));
    }

    function computeAddress(
        address[] calldata _owners,
        uint8 _threshold
    ) public view returns (address) {
        bytes32 salt = computeSalt(_owners[0]);

        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        type(SmartSafe).creationCode,
                                        abi.encode(_owners, _threshold)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function deploySmartSafe(
        address[] calldata _owners,
        uint8 _threshold
    ) external {
        bytes32 salt = computeSalt(_owners[0]);
        address predictedAddress = computeAddress(_owners, _threshold);

        SmartSafe newlyDeployedContract = new SmartSafe{salt: salt}();

        if (address(newlyDeployedContract) != predictedAddress) {
            revert InvalidContractAddress();
        }
        newlyDeployedContract.setupOwners(_owners, _threshold);

        nonce++;

        emit Deployed(address(newlyDeployedContract));
    }
}
