// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title This contract manages the transactions created by users.
 * @author Ricardo Passos - @ricardo-passos
 */
contract TransactionManager {
    error TransactionAlreadyProcessed();

    event TransactionSignatureAdded(uint64 indexed);
    event TransactionProposalCreated(uint64 indexed);

    enum TransactionStatus {
        Queued,
        Processed
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

    uint64 internal executedSize = 0;
    uint64 public transactionNonce = 0;
    uint64 public requiredTransactionNonce = 0;

    uint8 internal constant MAX_RETURN_SIZE = 10;

    mapping(uint64 => Transaction) internal transactionExecuted;
    mapping(uint64 => Transaction) internal transactionQueue;

    mapping(uint64 => uint8) internal transactionApprovalsCount;
    mapping(uint64 => uint8) internal transactionRejectionsCount;
    mapping(uint64 => mapping(address => bool)) public transactionApprovals;

    function getQueueTransactions(
        uint32 _page
    ) external view returns (Transaction[] memory) {
        // `requiredTransactionNonce` serves a pointer to at which index
        // start fethcing ``
        uint64 startIndex = (_page * MAX_RETURN_SIZE) +
            requiredTransactionNonce;
        uint64 endIndex = startIndex + MAX_RETURN_SIZE;
        if (endIndex > (transactionNonce - requiredTransactionNonce)) {
            endIndex = (transactionNonce - requiredTransactionNonce);
        }

        Transaction[] memory listOfTransactions = new Transaction[](endIndex);

        for (uint64 i = 0; i < endIndex; i++) {
            if (startIndex + i >= transactionNonce) {
                break;
            }

            listOfTransactions[i] = transactionQueue[startIndex + i];
        }

        return listOfTransactions;
    }

    function getExecutedTransactions(
        uint32 _page
    ) external view returns (Transaction[] memory) {
        uint64 startIndex = _page * MAX_RETURN_SIZE;
        uint64 endIndex = startIndex + MAX_RETURN_SIZE;
        if (endIndex > executedSize) {
            endIndex = executedSize;
        }
        uint64 length = endIndex - startIndex;
        Transaction[] memory listOfTransactions = new Transaction[](length);

        for (uint64 i = 0; i < length; i++) {
            if (startIndex + i >= executedSize) {
                break;
            }
            listOfTransactions[i] = transactionExecuted[startIndex + i];
        }

        return listOfTransactions;
    }

    function getFromTransactionQueue(
        uint64 _transactionNonce
    ) internal view returns (Transaction storage) {
        return transactionQueue[_transactionNonce];
    }

    function getFromTransactionQueueSignatures(
        uint64 _transactionNonce
    ) internal view returns (bytes[] memory) {
        return transactionQueue[_transactionNonce].signatures;
    }

    function createTransactionProposal(
        address _to,
        uint256 _value,
        bytes calldata _data,
        address _signer,
        bytes memory _transactionProposalSignature
    ) internal {
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = _transactionProposalSignature;

        Transaction memory transactionProposal = Transaction({
            from: address(this),
            to: _to,
            value: _value,
            transactionNonce: transactionNonce,
            createdAt: block.timestamp,
            data: _data,
            signatures: signatures
        });

        uint64 currentTransactionNonce = transactionNonce;
        // add transaction to queue
        transactionQueue[transactionNonce] = transactionProposal;
        // mark transaction as approved by _signer
        transactionApprovals[transactionNonce][_signer] = true;
        // increase total transaction approvals for this transaction
        transactionApprovalsCount[transactionNonce]++;

        transactionNonce++;

        emit TransactionProposalCreated(currentTransactionNonce);
    }

    function addTransactionSignature(
        uint64 _transactionNonce,
        address _signer,
        bool _transactionApprovalType,
        bytes memory _transactionProposalSignature
    ) internal {
        transactionQueue[_transactionNonce].signatures.push(
            _transactionProposalSignature
        );

        transactionApprovals[_transactionNonce][
            _signer
        ] = _transactionApprovalType;
        // increase transaction approvals or rejections based on `_signer`'s choice
        _transactionApprovalType == true
            ? transactionApprovalsCount[_transactionNonce]++
            : transactionRejectionsCount[_transactionNonce]++;

        emit TransactionSignatureAdded(_transactionNonce);
    }

    function updateExecutedTransactions() internal {
        executedSize++;
    }

    function removeTransaction() public virtual {
        moveTransactionFromQueueToHistory(requiredTransactionNonce);

        requiredTransactionNonce++;
        updateExecutedTransactions();
    }

    function moveTransactionFromQueueToHistory(
        uint64 _transactionNonce
    ) internal {
        Transaction memory executedTransaction = getFromTransactionQueue(
            _transactionNonce
        );

        if (executedTransaction.createdAt == 0) {
            revert TransactionAlreadyProcessed();
        }

        transactionExecuted[_transactionNonce] = executedTransaction;

        delete transactionQueue[_transactionNonce];
    }
}
