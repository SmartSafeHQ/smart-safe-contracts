// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// vendor
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import {ISmartSafe} from "../../interfaces/core/ISmartSafe.sol";
import {ApprovalStatus, TransactionState, TransactionApproval, Transaction} from "../../interfaces/core/ITransactionManager.sol";

contract Automation is AutomationCompatibleInterface {
    error InvalidTrigger();
    error InvalidTransactionNonce();
    error TransactionNotReadyForExecution();
    error InsufficientApprovalsForTransaction();

    struct ScheduledTransaction {
        address from;
        address to;
        uint64 transactionNonce;
        uint256 value;
        uint256 createdAt;
        uint256 interval;
        bytes data;
        bytes[] signatures;
    }

    ISmartSafe public smartSafeImpl;

    mapping(uint64 => ScheduledTransaction) scheduledTransactions;

    // tx nonce -> evm timestamp
    mapping(uint64 => uint256) lastExecutionTime;

    constructor(address _smartSafeImpl) {
        smartSafeImpl = ISmartSafe(_smartSafeImpl);
    }

    function createScheduledTransaction(
        // transaction related
        address _to,
        uint256 _value,
        bytes calldata _data,
        uint256 _interval,
        // signature related
        address _transactionProposalSigner,
        bytes memory _transactionProposalSignature
    ) external {
        if (_interval == 0) {
            revert InvalidTrigger();
        }

        uint64 transactionNonce = smartSafeImpl.transactionNonce();

        smartSafeImpl.createTransactionProposal(
            _to,
            _value,
            _data,
            _transactionProposalSigner,
            _transactionProposalSignature
        );

        Transaction memory newlyCreatedTransaction = smartSafeImpl
            .getTransaction(TransactionState.Queued, transactionNonce);

        ScheduledTransaction memory transaction = ScheduledTransaction({
            from: address(smartSafeImpl),
            to: _to,
            value: _value,
            data: _data,
            createdAt: newlyCreatedTransaction.createdAt,
            interval: _interval,
            transactionNonce: transactionNonce,
            signatures: newlyCreatedTransaction.signatures
        });

        lastExecutionTime[transactionNonce] = block.timestamp;
        scheduledTransactions[transactionNonce] = transaction;
    }

    function addTransactionSignature(
        address _transactionProposalSigner,
        ApprovalStatus _transactionApprovalType,
        bytes memory _transactionProposalSignature
    ) external {
        smartSafeImpl.addTransactionSignature(
            _transactionProposalSigner,
            _transactionApprovalType,
            _transactionProposalSignature
        );

        uint64 transactionNonce = smartSafeImpl.requiredTransactionNonce();

        uint8 transactionApprovalsCount = smartSafeImpl
            .transactionApprovalsCount(transactionNonce);
        uint8 smartSafeThreshold = smartSafeImpl.threshold();

        // once we get all required approvals, we remove the proposal from the main
        // queue so that other proposals can be created.
        if (transactionApprovalsCount == smartSafeThreshold) {
            smartSafeImpl.removeProposal(transactionNonce);
        }
    }

    function checkUpkeep(bytes calldata _checkData)
        external
        view
        returns (bool _upkeepNeeded, bytes memory _performData)
    {
        uint64 transactionNonce = abi.decode(_checkData, (uint64));

        checkForTransactionValidity(transactionNonce);

        return (true, _checkData);
    }

    function performUpkeep(bytes calldata _performData) external {
        uint64 transactionNonce = abi.decode(_performData, (uint64));

        ScheduledTransaction
            memory scheduledTransaction = checkForTransactionValidity(
                transactionNonce
            );

        lastExecutionTime[transactionNonce] = block.timestamp;

        smartSafeImpl.executeTransactionFromModule(
            scheduledTransaction.to,
            scheduledTransaction.value,
            scheduledTransaction.data
        );
    }

    function checkForTransactionValidity(uint64 _transactionNonce)
        private
        view
        returns (ScheduledTransaction memory)
    {
        uint8 transactionApprovalsCount = smartSafeImpl
            .transactionApprovalsCount(_transactionNonce);
        uint8 smartSafeThreshold = smartSafeImpl.threshold();

        if (transactionApprovalsCount < smartSafeThreshold) {
            revert InsufficientApprovalsForTransaction();
        }

        uint64 currentTransactionNonce = smartSafeImpl.transactionNonce();
        uint64 currentRequiredTransactionNonce = smartSafeImpl
            .requiredTransactionNonce();

        if (
            _transactionNonce < currentRequiredTransactionNonce ||
            _transactionNonce > currentTransactionNonce
        ) {
            revert InvalidTransactionNonce();
        }

        ScheduledTransaction
            memory scheduledTransaction = scheduledTransactions[
                _transactionNonce
            ];

        if (
            (block.timestamp - lastExecutionTime[_transactionNonce]) <
            scheduledTransaction.interval
        ) {
            revert TransactionNotReadyForExecution();
        }

        return scheduledTransaction;
    }
}
