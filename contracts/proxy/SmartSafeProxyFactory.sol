// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SmartSafeProxy} from "./SmartSafeProxy.sol";

contract SmartSafeProxyFactory {
    address public immutable owner;
    uint64 internal nonce = 0;

    event Deployed(address indexed);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "[SmartSafeFactory#onlyOwner]: Caller is not the owner."
        );

        _;
    }

    function computeSalt(address _owner) private view returns (bytes32) {
        return keccak256(abi.encode(nonce, _owner));
    }

    function computeAddress(address _owner) public view returns (address) {
        bytes32 salt = computeSalt(_owner);

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
                                        type(SmartSafeProxy).creationCode,
                                        abi.encode(_owner)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function deploySmartSafeProxy(address _smartSafe) external onlyOwner {
        bytes32 salt = computeSalt(_smartSafe);
        address predictedAddress = computeAddress(_smartSafe);

        SmartSafeProxy newlyDeployedContract = new SmartSafeProxy{salt: salt}(_smartSafe);

        require(address(newlyDeployedContract) == predictedAddress);

        nonce++;

        emit Deployed(address(newlyDeployedContract));
    }
}
