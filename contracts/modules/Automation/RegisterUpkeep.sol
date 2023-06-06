// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IKeeperRegistrar} from "../../interfaces/chainlink/IKeeperRegistrar.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract RegisterUpkeep {
    event UpkeepRegistered(uint256);

    error UpKeepRegistrationFailed();

    LinkTokenInterface public immutable linkTokenContract;
    IKeeperRegistrar public immutable registrarContract;

    constructor(
        LinkTokenInterface _linkTokenAddress,
        IKeeperRegistrar _registrarContractAddress
    ) {
        linkTokenContract = _linkTokenAddress;
        registrarContract = _registrarContractAddress;
    }

    function registerAndPredictID(
        IKeeperRegistrar.RegistrationParams memory params
    ) external {
        linkTokenContract.approve(address(registrarContract), params.amount);
        uint256 upkeepID = registrarContract.registerUpkeep(params);

        if (upkeepID != 0) {
            emit UpkeepRegistered(upkeepID);
        } else {
            revert UpKeepRegistrationFailed();
        }
    }
}
