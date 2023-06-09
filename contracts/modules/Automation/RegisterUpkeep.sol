// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IKeeperRegistrar} from "../../interfaces/chainlink/IKeeperRegistrar.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract RegisterUpkeep {
    event UpkeepRegistered(uint256);

    error UpKeepRegistrationFailed(bytes);

    LinkTokenInterface private immutable linkTokenContract;
    IKeeperRegistrar private immutable registrarContract;

    // safe address -> safe tx nonce -> upkeepID
    mapping(address => mapping(uint64 => uint256)) public upKeepsPerSmartSafe;

    constructor(
        LinkTokenInterface _linkTokenAddress,
        IKeeperRegistrar _registrarContractAddress
    ) {
        linkTokenContract = _linkTokenAddress;
        registrarContract = _registrarContractAddress;
    }

    function registerAndPredictID(
        IKeeperRegistrar.RegistrationParams memory _params
    ) external {
        linkTokenContract.approve(address(registrarContract), _params.amount);

        uint256 upKeepID = registrarContract.registerUpkeep(_params);

        uint64 _transactionNonce = abi.decode(_params.checkData, (uint64));

        upKeepsPerSmartSafe[_params.upkeepContract][
            _transactionNonce
        ] = upKeepID;
    }
}
