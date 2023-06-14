// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

enum ApprovalStatus {
    Pending,
    Approved,
    Rejected
}

enum TransactionState {
    Queued,
    Executed
}

struct TransactionApproval {
    address owner;
    ApprovalStatus status;
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

interface ITransactionManager {
    function transactionNonce() external view returns (uint64);

    function requiredTransactionNonce() external view returns (uint64);

    function executedTransactionsSize() external view returns (uint64);

    function scheduledTransactionsSize() external view returns (uint64);

    function transactionApprovalsCount(uint64 _transactionNonce)
        external
        view
        returns (uint8);

    function transactionRejectionsCount(uint64 _transactionNonce)
        external
        view
        returns (uint8);

    function transactionQueue(uint64 _transactionNonce)
        external
        view
        returns (Transaction memory);

    function transactionExecuted(uint64 _transactionNonce)
        external
        view
        returns (Transaction memory);

    function getTransaction(
        TransactionState _transactionType,
        uint64 _transactionNonce
    ) external view returns (Transaction memory);
}
