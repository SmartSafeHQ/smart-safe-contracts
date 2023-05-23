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
        Active,
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

    uint64 public transactionNonce = 0;
    uint8 constant MAX_RETURN_SIZE = 10;
    mapping(uint64 => Transaction) private transactionQueue;
    mapping(uint64 => Transaction) private transactionHistory;

    function getFromTransactionQueue(
        uint64 _transactionNonce
    ) internal view returns (Transaction storage) {
        return transactionQueue[_transactionNonce];
    }

    function getTransactions(
        uint32 _page,
        TransactionStatus _transactionStatus
    ) external view returns (Transaction[] memory) {
        uint64 startIndex = _page * MAX_RETURN_SIZE;
        uint64 endIndex = startIndex + MAX_RETURN_SIZE;
        if (endIndex > transactionNonce) {
            endIndex = transactionNonce;
        }
        uint64 length = endIndex - startIndex;
        Transaction[] memory listOfTransactions = new Transaction[](length);

        if (_transactionStatus == TransactionStatus.Active) {
            for (uint64 i = 0; i < length; i++) {
                if (startIndex + i >= transactionNonce) {
                    break;
                }
                listOfTransactions[i] = transactionQueue[startIndex + i];
            }
        } else {
            for (uint64 i = 0; i < length; i++) {
                if (startIndex + i >= transactionNonce) {
                    break;
                }
                listOfTransactions[i] = transactionHistory[startIndex + i];
            }
        }

        return listOfTransactions;
    }

    function getFromTransactionQueueSignatures(
        uint64 _transactionNonce
    ) internal view returns (bytes[] memory) {
        return transactionQueue[_transactionNonce].signatures;
    }

    function deleteTransaction(uint64 _transactionNonce) internal {
        delete transactionQueue[_transactionNonce];

        transactionNonce++;
    }

    function createTransactionProposal(
        address _to,
        uint256 _value,
        bytes calldata _data,
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
        transactionQueue[transactionNonce] = transactionProposal;
        transactionNonce++;

        emit TransactionProposalCreated(currentTransactionNonce);
    }

    function addTransactionSignature(
        uint64 _transactionNonce,
        bytes memory _transactionProposalSignature
    ) internal {
        transactionQueue[_transactionNonce].signatures.push(
            _transactionProposalSignature
        );

        emit TransactionSignatureAdded(_transactionNonce);
    }

    function moveTransactionFromQueueToHistory(
        uint64 _transactionNonce
    ) internal {
        Transaction memory executedTransaction = getFromTransactionQueue(
            _transactionNonce
        );

        if (
            executedTransaction.from == address(0) ||
            executedTransaction.to == address(0)
        ) {
            revert TransactionAlreadyProcessed();
        }

        transactionHistory[_transactionNonce] = executedTransaction;

        delete transactionQueue[_transactionNonce];
    }
}
