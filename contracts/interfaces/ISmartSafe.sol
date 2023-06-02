// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ITransactionManager} from "./ITransactionManager.sol";

interface ISmartSafe {
    function setupOwners(
        address[] memory _owners,
        uint8 _threshold
    ) external payable;

    function executeTransaction(uint64 _transactionNonce) external;

    function createTransactionProposal(
        // transaction related
        address _to,
        uint256 _value,
        bytes calldata _data,
        // signature related
        address _transactionProposalSigner,
        bytes memory _transactionProposalSignature
    ) external payable;

    function removeTransaction() external;

    function getTransactionApprovals(
        uint64 _transactionNonce
    ) external view returns (ITransactionManager.TransactionApprovals[] memory);

    function addTransactionSignature(
        address _transactionProposalSigner,
        ITransactionManager.TransactionApproval _transactionApprovalType,
        bytes memory _transactionProposalSignature
    ) external;
}
