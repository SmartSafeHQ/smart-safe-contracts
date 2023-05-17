// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @author Ricardo Passos - @ricardo-passos
 */
contract SmartSafeProxyFactory {
    error DeployFailed(bytes);
    error CallerIsNotAnOwner();
    error NotAValidSmartSafeImpl();
    error MismatchedAddress(address required, address received);

    event Called(bytes);
    event Deployed(address indexed);

    address private owner;
    address public smartSafeImplementation;

    constructor(address _owner, address _smartSafeImplementation) {
        owner = _owner;

        if (isContract(_smartSafeImplementation) == false) {
            revert NotAValidSmartSafeImpl();
        }

        smartSafeImplementation = _smartSafeImplementation;
    }

    function renounceOwnernship(address _newOwner) external {
        onlyOwner(msg.sender);

        owner = _newOwner;
    }

    function setSmartSafeImplementation(
        address _newSmartSafeImplementation
    ) external {
        onlyOwner(msg.sender);

        if (isContract(_newSmartSafeImplementation) == false) {
            revert NotAValidSmartSafeImpl();
        }

        smartSafeImplementation = _newSmartSafeImplementation;
    }

    function computeAddress(bytes32 _salt) public view returns (address) {
        return
            Clones.predictDeterministicAddress(smartSafeImplementation, _salt);
    }

    function deploySmartSafeProxy(
        address[] calldata _owners,
        uint8 _threshold,
        bytes32 _salt
    ) external payable {
        address predictedAddress = computeAddress(_salt);

        address deployedProxyAddress = Clones.cloneDeterministic(
            smartSafeImplementation,
            _salt
        );

        if (deployedProxyAddress != predictedAddress) {
            revert MismatchedAddress(predictedAddress, deployedProxyAddress);
        }

        bytes memory initializeSmartSafeData = abi.encodeWithSignature(
            "setupOwners(address[],uint8)",
            _owners,
            _threshold
        );
        (bool success, bytes memory returndata) = deployedProxyAddress.call{
            value: msg.value
        }(initializeSmartSafeData);

        if (!success && returndata.length > 0) {
            revert DeployFailed(returndata);
        }

        emit Deployed(deployedProxyAddress);
    }

    function isContract(address _address) private view returns (bool) {
        return _address.code.length > 0;
    }

    function onlyOwner(address _owner) private view {
        if (_owner != owner) {
            revert CallerIsNotAnOwner();
        }
    }
}
