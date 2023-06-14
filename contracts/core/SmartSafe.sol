// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// vendor
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// modules
import {OwnerManager} from "./OwnerManager.sol";
import {ExecuteManager} from "./ExecuteManager.sol";
import {ModulesManager} from "./ModulesManager.sol";
import {FallbackManager} from "./FallbackManager.sol";
import {SignatureManager} from "./SignatureManager.sol";
import {TransactionManager} from "./TransactionManager.sol";

import {ApprovalStatus, Transaction, TransactionApproval, TransactionState} from "../interfaces/core/ITransactionManager.sol";

/**
 * @title A multi-signature safe to secure digital assets.
 * @author Ricardo Passos - @ricardo-passos
 */
contract SmartSafe is
    OwnerManager,
    Initializable,
    ExecuteManager,
    ModulesManager,
    FallbackManager,
    ReentrancyGuard,
    SignatureManager,
    TransactionManager
{
    error InsufficientBalance();
    error InsufficientSignatures();
    error SignaturesAlreadyCollected();
    error TransactionNonceError(uint64 required, uint64 received);

    event TransactionExecutionSucceeded(uint64);

    /**
     * @dev
     * This function essentially initializes a Smart Safe after user
     * deploys a proxy.
     * @notice User can optionally send network native tokens (ETH, BNB, etc).
     */
    function setupOwners(address[] memory _owners, uint8 _threshold)
        external
        payable
        initializer
    {
        if (
            _owners.length == 0 ||
            _threshold == 0 ||
            _threshold > _owners.length
        ) {
            revert OwnerManager.OutOfBoundsThreshold();
        }

        OwnerManager._setupOwners(_owners, _threshold);
    }

    function executeTransaction(uint64 _transactionNonce) public nonReentrant {
        isCallerAuthorized();

        Transaction memory proposedTransaction = TransactionManager
            .getTransaction(TransactionState.Queued, _transactionNonce);

        uint64 requiredTransactionNonce = TransactionManager
            .requiredTransactionNonce;
        uint64 proposedTransactionNonce = proposedTransaction.transactionNonce;
        if (proposedTransactionNonce != requiredTransactionNonce) {
            revert TransactionNonceError(
                requiredTransactionNonce,
                proposedTransactionNonce
            );
        }

        if (address(this).balance < proposedTransaction.value) {
            revert InsufficientBalance();
        }

        uint8 signaturesCount = uint8(proposedTransaction.signatures.length);
        if (signaturesCount < OwnerManager.threshold) {
            revert InsufficientSignatures();
        }

        ExecuteManager.executeTransaction(
            proposedTransaction.to,
            proposedTransaction.value,
            proposedTransaction.data
        );

        TransactionManager.requiredTransactionNonce++;
        TransactionManager.executedTransactionsSize++;

        TransactionManager.moveTransaction(
            TransactionManager.transactionQueue,
            TransactionManager.transactionExecuted,
            requiredTransactionNonce
        );

        emit TransactionExecutionSucceeded(_transactionNonce);
    }

    function createTransactionProposal(
        // transaction related
        address _to,
        uint256 _value,
        bytes calldata _data,
        // signature related
        address _transactionProposalSigner,
        bytes memory _transactionProposalSignature
    ) external payable {
        checkTransaction(
            _to,
            _value,
            _data,
            TransactionManager.transactionNonce,
            _transactionProposalSigner,
            _transactionProposalSignature
        );

        TransactionManager._createTransactionProposal(
            _to,
            _value,
            _data,
            _transactionProposalSigner,
            _transactionProposalSignature
        );
    }

    function addTransactionSignature(
        address _transactionProposalSigner,
        ApprovalStatus _transactionApprovalType,
        bytes memory _transactionProposalSignature
    ) external {
        Transaction memory transaction = TransactionManager.getTransaction(
            TransactionState.Queued,
            requiredTransactionNonce
        );

        checkTransaction(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.transactionNonce,
            _transactionProposalSigner,
            _transactionProposalSignature
        );

        TransactionManager.addTransactionSignature(
            requiredTransactionNonce,
            _transactionProposalSigner,
            _transactionApprovalType,
            _transactionProposalSignature
        );

        // Automatically remove transaction from queue if rejections is equal
        // or greather than `threshold`
        uint8 rejectionsCount = TransactionManager.transactionRejectionsCount[
            requiredTransactionNonce
        ];
        if (rejectionsCount >= OwnerManager.totalOwners / 2) {
            TransactionManager.requiredTransactionNonce++;
            TransactionManager.executedTransactionsSize++;

            TransactionManager.moveTransaction(
                TransactionManager.transactionQueue,
                TransactionManager.transactionExecuted,
                requiredTransactionNonce
            );
        }
    }

    /**
    * @notice This function removes a single proposal.
    */
    function removeProposal(uint64 _transactionNonce) external {
        isCallerAuthorized();

        TransactionManager.moveTransaction(
            TransactionManager.transactionQueue,
            TransactionManager.transactionExecuted,
            _transactionNonce
        );

        TransactionManager.requiredTransactionNonce++;
        TransactionManager.executedTransactionsSize++;
    }

    /**
    * @notice This function will remove all pending proposals.
    */
    function replaceNonce() external {
        isCallerAuthorized();

        while (
            TransactionManager.requiredTransactionNonce <
            TransactionManager.transactionNonce
        ) {
            TransactionManager.moveTransaction(
                TransactionManager.transactionQueue,
                TransactionManager.transactionExecuted,
                TransactionManager.requiredTransactionNonce
            );

            TransactionManager.requiredTransactionNonce++;
            TransactionManager.executedTransactionsSize++;
        }
    }

    function getTransactionApprovals(uint64 _transactionNonce)
        external
        view
        returns (TransactionApproval[] memory)
    {
        return
            TransactionManager.getTransactionApprovals(
                _transactionNonce,
                OwnerManager.getOwners()
            );
    }

    /**
     * @dev
     * Although the use of the `modifier` keyword is considered semantically correct,
     * the final bytecode gets larger. Using a function is cheaper.
     * Making this simple modification reduced the final bytecode by 2kb.
     */
    function checkTransaction(
        // transaction related
        address _to,
        uint256 _value,
        bytes memory _data,
        uint64 _transactionNonce,
        // signature related
        address _transactionProposalSigner,
        bytes memory _transactionProposalSignature
    ) private view {
        isCallerAuthorized();

        SignatureManager.checkTransactionSignature(
            address(this),
            _to,
            _transactionNonce,
            _value,
            _data,
            _transactionProposalSigner,
            _transactionProposalSignature
        );
    }

    function isCallerAuthorized() private view {
        if (
            !OwnerManager.isSafeOwner(msg.sender) &&
            !ModulesManager.isSafeModule(msg.sender)
        ) {
            revert CallerIsNotAuthorized();
        }
    }
}
