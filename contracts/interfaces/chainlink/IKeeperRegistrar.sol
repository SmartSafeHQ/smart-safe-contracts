// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IKeeperRegistrar {
    struct RegistrationParams {
        string name;
        bytes encryptedEmail;
        address upkeepContract;
        uint32 gasLimit;
        address adminAddress;
        bytes checkData;
        bytes offchainConfig;
        uint96 amount;
    }

    function registerUpkeep(RegistrationParams calldata _params)
        external
        returns (uint256);
}
