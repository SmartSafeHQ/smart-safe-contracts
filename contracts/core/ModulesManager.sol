// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ExecuteManager} from "./ExecuteManager.sol";
import {SelfAuthorized} from "../utils/SelfAuthorized.sol";

/**
 * @title This contract manages modules that are plugged to the user's Smart Safe instance.
 * @author Ricardo Passos - @ricardo-passos
 */
contract ModulesManager is SelfAuthorized, ExecuteManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private modules;

    function addModule(address _moduleAddress) public {
        SelfAuthorized.authorized();

        modules.add(_moduleAddress);
    }

    function removeModule(address _moduleAddress) public {
        SelfAuthorized.authorized();

        modules.remove(_moduleAddress);
    }

    function getModules() public view returns (address[] memory) {
        return modules.values();
    }

    function isSafeModule(address _moduleAddress) internal view returns (bool) {
        if (!modules.contains(_moduleAddress)) {
            return false;
        }

        return true;
    }

    function executeTransactionFromModule(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external returns (bytes memory) {
        if (!isSafeModule(msg.sender)) {
            revert CallerIsNotAuthorized();
        }

        return ExecuteManager.executeTransaction(_to, _value, _data);
    }
}
