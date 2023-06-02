// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITransactionManager {
    enum TransactionApproval {
        Awaiting,
        Approved,
        Rejected
    }

    enum TransactionStatus {
        Queued,
        Executed
    }

    struct TransactionApprovals {
        address ownerAddress;
        TransactionApproval approvalStatus;
    }

    struct Transaction {
        address from;
        address to;
        uint64 transactionNonce;
        uint256 value;
        uint256 createdAt;
        bytes data;
        bytes[] signatures;
    }

    function transactionNonce() external view returns (uint64);

    function requiredTransactionNonce() external view returns (uint64);

    function getTransactions(
        uint8 _page,
        TransactionStatus _transactionStatus
    ) external view returns (Transaction[] memory);

    function removeTransaction() external;
}
