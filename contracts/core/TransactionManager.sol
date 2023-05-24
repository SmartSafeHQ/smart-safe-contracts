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

    uint64 public transactionNonce = 0;
    uint64 internal requiredTransactionNonce = 0;
    uint8 private constant MAX_RETURN_SIZE = 10;
    mapping(uint64 => Transaction) private transactionQueue;
    mapping(uint64 => Transaction) private transactionHistory;

    mapping(uint64 => uint8) public transactionApprovalsCount;
    mapping(uint64 => uint8) public transactionRejectionsCount;
    mapping(uint64 => mapping(address => bool)) public transactionApprovals;

    function getFromTransactionQueue(
        uint64 _transactionNonce
    ) internal view returns (Transaction storage) {
        return transactionQueue[_transactionNonce];
    }

    /**
     * @dev Keep in mind that even if the `queue` or `history` mappings have no entries,
     * Solidity will still return a list of `Transaction`s of `length` size but all values will be zeroed. 
     * This is because the `listOfTransactions` array is sometimes created based on `transactionNonce`. 
     * So, even if you have 2 transactions in `transactionHistory` and 0 transactions in `transactionHistory` 
     * and you run a query on the `transactionHistory` mapping, it will return an array of `length` 2 with all items
     * zeroed.
     */
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

        if (_transactionStatus == TransactionStatus.Queued) {
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

    function moveTransactionFromQueueToHistory(
        uint64 _transactionNonce
    ) internal {
        Transaction memory executedTransaction = getFromTransactionQueue(
            _transactionNonce
        );

        if (executedTransaction.createdAt == 0) {
            revert TransactionAlreadyProcessed();
        }

        transactionHistory[_transactionNonce] = executedTransaction;

        delete transactionQueue[_transactionNonce];
    }
}
