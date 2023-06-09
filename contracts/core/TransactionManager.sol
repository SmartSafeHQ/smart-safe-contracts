// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

    enum TransactionApproval {
        Awaiting,
        Approved,
        Rejected
    }

    enum TransactionStatus {
        Queued,
        Executed,
        Scheduled
    }

    enum TransactionRecurrence {
        None,
        EveryMinute,
        EveryFiveMinutes,
        Hourly,
        Daily,
        Weekly,
        Monthly,
        Yearly
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
        TransactionRecurrence trigger;
    }

    uint64 public transactionNonce = 0;
    uint64 public requiredTransactionNonce = 0;
    uint64 internal executedTransactionsSize = 0;
    uint64 internal scheduledTransactionsSize = 0;

    uint8 internal constant MAX_RETURN_SIZE = 10;

    mapping(uint64 => Transaction) internal transactionQueue;
    mapping(uint64 => Transaction) internal transactionExecuted;
    mapping(uint64 => Transaction) internal transactionScheduled;
    // tx nonce -> block.timestamp
    mapping(uint64 => uint256) internal lastExecutionTime;

    mapping(uint64 => uint8) internal transactionApprovalsCount;
    mapping(uint64 => uint8) internal transactionRejectionsCount;
    mapping(uint64 => mapping(address => TransactionApproval))
        private transactionApprovals;

    function getTransactionApprovals(
        uint64 _transactionNonce,
        address[] memory _owners
    ) internal view returns (TransactionApprovals[] memory) {
        TransactionApprovals[] memory approvals = new TransactionApprovals[](
            _owners.length
        );

        uint256 nonZeroCount = 0; // Counter for non-zero approvals

        for (uint8 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            TransactionApproval vote = transactionApprovals[_transactionNonce][
                owner
            ];

            if (vote != TransactionApproval.Awaiting) {
                approvals[nonZeroCount] = TransactionApprovals({
                    ownerAddress: owner,
                    approvalStatus: vote
                });
                nonZeroCount++;
            }
        }

        // Create a new array with non-zero approvals only
        TransactionApprovals[]
            memory nonZeroApprovals = new TransactionApprovals[](nonZeroCount);
        for (uint256 i = 0; i < nonZeroCount; i++) {
            nonZeroApprovals[i] = approvals[i];
        }

        return nonZeroApprovals;
    }

    function getQueueTransactions(uint32 _page)
        internal
        view
        returns (Transaction[] memory)
    {
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

    function getScheduledTransactions(uint32 _page)
        internal
        view
        returns (Transaction[] memory)
    {
        uint64 startIndex = _page * MAX_RETURN_SIZE;
        uint64 endIndex = startIndex + MAX_RETURN_SIZE;
        if (endIndex > scheduledTransactionsSize) {
            endIndex = scheduledTransactionsSize;
        }
        uint64 length = endIndex - startIndex;
        Transaction[] memory listOfTransactions = new Transaction[](length);

        for (uint64 i = 0; i < length; i++) {
            if (startIndex + i >= scheduledTransactionsSize) {
                break;
            }
            listOfTransactions[i] = transactionScheduled[startIndex + i];
        }

        return listOfTransactions;
    }

    function getExecutedTransactions(uint32 _page)
        internal
        view
        returns (Transaction[] memory)
    {
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

    function getTransactions(uint8 _page, TransactionStatus _transactionStatus)
        external
        view
        returns (Transaction[] memory _transactions)
    {
        if (_transactionStatus == TransactionStatus.Queued) {
            return getQueueTransactions(_page);
        } else if (_transactionStatus == TransactionStatus.Executed) {
            return getExecutedTransactions(_page);
        } else if (_transactionStatus == TransactionStatus.Scheduled) {
            return getScheduledTransactions(_page);
        }
    }

    function getTransactionFromQueue(uint64 _transactionNonce)
        internal
        view
        returns (Transaction memory)
    {
        return transactionQueue[_transactionNonce];
    }

    function getSignaturesFromTransactionQueue(uint64 _transactionNonce)
        internal
        view
        returns (bytes[] memory)
    {
        return transactionQueue[_transactionNonce].signatures;
    }

    function _createTransactionProposal(
        address _to,
        uint256 _value,
        bytes calldata _data,
        TransactionRecurrence _trigger,
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
            signatures: signatures,
            trigger: _trigger
        });

        uint64 currentTransactionNonce = transactionNonce;
        // add transaction to queue
        transactionQueue[transactionNonce] = transactionProposal;
        // mark transaction as approved by _signer
        transactionApprovals[transactionNonce][_signer] = TransactionApproval
            .Approved;
        // increase total transaction approvals for this transaction
        transactionApprovalsCount[transactionNonce]++;

        transactionNonce++;

        emit TransactionProposalCreated(currentTransactionNonce);
    }

    function addTransactionSignature(
        uint64 _transactionNonce,
        address _signer,
        TransactionApproval _transactionApprovalType,
        bytes memory _transactionProposalSignature
    ) internal {
        if (_transactionApprovalType == TransactionApproval.Awaiting) {
            revert InvalidTransactionApprovalType();
        }

        TransactionApproval hasOwnerAlreadySignedTransaction = transactionApprovals[
                _transactionNonce
            ][_signer];

        if (hasOwnerAlreadySignedTransaction != TransactionApproval.Awaiting) {
            revert OwnerAlreadySigned();
        }

        transactionQueue[_transactionNonce].signatures.push(
            _transactionProposalSignature
        );

        // increase transaction approvals or rejections based on `_signer`'s choice
        if (_transactionApprovalType == TransactionApproval.Approved) {
            transactionApprovalsCount[_transactionNonce]++;
            transactionApprovals[_transactionNonce][
                _signer
            ] = TransactionApproval.Approved;
        } else {
            transactionRejectionsCount[_transactionNonce]++;
            transactionApprovals[_transactionNonce][
                _signer
            ] = TransactionApproval.Rejected;
        }

        emit TransactionSignatureAdded(_transactionNonce);
    }

    function removeTransaction() public virtual {
        moveTransaction(
            transactionQueue,
            transactionExecuted,
            requiredTransactionNonce
        );

        requiredTransactionNonce++;
        executedTransactionsSize++;
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
