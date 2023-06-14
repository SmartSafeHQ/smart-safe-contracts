// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ApprovalStatus, TransactionState, TransactionApproval, Transaction} from "../interfaces/core/ITransactionManager.sol";

/**
 * @title This contract manages the transactions created by users.
 * @author Ricardo Passos - @ricardo-passos
 */
contract TransactionManager {
    error OwnerAlreadySigned();
    error OwnersLengthOutOfBounds();
    error TransactionAlreadyExecuted();
    error InvalidTransactionApprovalType();

    event TransactionSignatureAdded(uint64 indexed);
    event TransactionProposalCreated(uint64 indexed);

    uint64 public transactionNonce = 0;
    uint64 public requiredTransactionNonce = 0;
    uint64 public executedTransactionsSize = 0;
    uint64 public scheduledTransactionsSize = 0;

    uint8 private constant MAX_RETURN_SIZE = 10;

    mapping(uint64 => Transaction) public transactionQueue;
    mapping(uint64 => Transaction) public transactionExecuted;

    mapping(uint64 => uint8) public transactionApprovalsCount;
    mapping(uint64 => uint8) public transactionRejectionsCount;
    mapping(uint64 => mapping(address => ApprovalStatus))
        private transactionApprovals;

    function getTransactionApprovals(
        uint64 _transactionNonce,
        address[] memory _owners
    ) internal view returns (TransactionApproval[] memory) {
        TransactionApproval[] memory approvals = new TransactionApproval[](
            _owners.length
        );

        uint256 nonZeroCount = 0; // Counter for non-zero approvals

        for (uint8 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            ApprovalStatus vote = transactionApprovals[_transactionNonce][
                owner
            ];

            if (vote != ApprovalStatus.Pending) {
                approvals[nonZeroCount] = TransactionApproval({
                    owner: owner,
                    status: vote
                });
                nonZeroCount++;
            }
        }

        // Create a new array with non-zero approvals only
        TransactionApproval[]
            memory nonZeroApprovals = new TransactionApproval[](nonZeroCount);
        for (uint256 i = 0; i < nonZeroCount; i++) {
            nonZeroApprovals[i] = approvals[i];
        }

        return nonZeroApprovals;
    }

    function getQueueTransactions(
        uint32 _page
    ) private view returns (Transaction[] memory) {
        // `requiredTransactionNonce` is used as a pointer to at which index
        // start fetching `Transaction`s.
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
    ) private view returns (Transaction[] memory) {
        uint64 startIndex = _page * MAX_RETURN_SIZE;
        uint64 endIndex = startIndex + MAX_RETURN_SIZE;
        if (endIndex > executedTransactionsSize) {
            endIndex = executedTransactionsSize;
        }
        uint64 length = endIndex - startIndex;
        Transaction[] memory listOfTransactions = new Transaction[](length);

        for (uint64 i = 0; i < length; i++) {
            if (startIndex + i >= executedTransactionsSize) {
                break;
            }

            listOfTransactions[i] = transactionExecuted[startIndex + i];
        }

        return listOfTransactions;
    }

    function getTransactions(
        uint8 _page,
        TransactionState _transactionStatus
    ) public view returns (Transaction[] memory) {
        return
            _transactionStatus == TransactionState.Queued
                ? getQueueTransactions(_page)
                : getExecutedTransactions(_page);
    }

    function getTransaction(
        TransactionState _transactionType,
        uint64 _transactionNonce
    ) public view returns (Transaction memory) {
        return
            _transactionType == TransactionState.Queued
                ? transactionQueue[_transactionNonce]
                : transactionExecuted[_transactionNonce];
    }

    function getSignaturesFromTransactionQueue(
        uint64 _transactionNonce
    ) internal view returns (bytes[] memory) {
        return transactionQueue[_transactionNonce].signatures;
    }

    function _createTransactionProposal(
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
        transactionApprovals[transactionNonce][_signer] = ApprovalStatus
            .Approved;
        // increase total transaction approvals for this transaction
        transactionApprovalsCount[transactionNonce]++;

        transactionNonce++;

        emit TransactionProposalCreated(currentTransactionNonce);
    }

    function addTransactionSignature(
        uint64 _transactionNonce,
        address _signer,
        ApprovalStatus _transactionApprovalType,
        bytes memory _transactionProposalSignature
    ) internal {
        if (_transactionApprovalType == ApprovalStatus.Pending) {
            revert InvalidTransactionApprovalType();
        }

        ApprovalStatus hasOwnerAlreadySignedTransaction = transactionApprovals[
            _transactionNonce
        ][_signer];

        if (hasOwnerAlreadySignedTransaction != ApprovalStatus.Pending) {
            revert OwnerAlreadySigned();
        }

        transactionQueue[_transactionNonce].signatures.push(
            _transactionProposalSignature
        );

        // increase transaction approvals or rejections based on `_signer`'s choice
        if (_transactionApprovalType == ApprovalStatus.Approved) {
            transactionApprovalsCount[_transactionNonce]++;
            transactionApprovals[_transactionNonce][_signer] = ApprovalStatus
                .Approved;
        } else {
            transactionRejectionsCount[_transactionNonce]++;
            transactionApprovals[_transactionNonce][_signer] = ApprovalStatus
                .Rejected;
        }

        emit TransactionSignatureAdded(_transactionNonce);
    }

    function moveTransaction(
        mapping(uint64 => Transaction) storage _fromMapping,
        mapping(uint64 => Transaction) storage _toMapping,
        uint64 _transactionNonce
    ) internal {
        Transaction memory transaction = _fromMapping[_transactionNonce];

        if (transaction.createdAt == 0) {
            revert TransactionAlreadyExecuted();
        }

        _toMapping[_transactionNonce] = transaction;

        delete _fromMapping[_transactionNonce];
    }
}
