// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IOwnerManager} from "./IOwnerManager.sol";
import {IModuleManager} from "./IModuleManager.sol";
import {ITransactionManager, ApprovalStatus} from "./ITransactionManager.sol";

interface ISmartSafe is ITransactionManager, IOwnerManager, IModuleManager {
    function createTransactionProposal(
        // transaction related
        address _to,
        uint256 _value,
        bytes calldata _data,
        // signature related
        address _transactionProposalSigner,
        bytes memory _transactionProposalSignature
    ) external;

    function addTransactionSignature(
        address _transactionProposalSigner,
        ApprovalStatus _transactionApprovalType,
        bytes memory _transactionProposalSignature
    ) external;

    function removeProposal(uint64 _transactionNonce) external;
}
