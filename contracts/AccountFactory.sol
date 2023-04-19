// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccountAbstraction} from "./AccountAbstraction.sol";

contract AccountFactory {
    address public immutable owner;
    uint64 public nonce = 0;

    event Deployed(address indexed);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "[AccountFactory#onlyOwner]: Caller is not the owner."
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
                                        type(AccountAbstraction).creationCode,
                                        abi.encode(_owner)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function deployContract(address _owner) external onlyOwner {
        bytes32 salt = computeSalt(_owner);
        address predictedAddress = computeAddress(_owner);

        AccountAbstraction newlyDeployedContract = new AccountAbstraction{
            salt: salt
        }(_owner);

        require(address(newlyDeployedContract) == predictedAddress);

        nonce++;

        emit Deployed(address(newlyDeployedContract));
    }
}
