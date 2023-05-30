// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {OwnerManager} from "./OwnerManager.sol";
import {FallbackManager} from "./FallbackManager.sol";
import {SignatureManager} from "./SignatureManager.sol";
import {TransactionManager} from "./TransactionManager.sol";

/**
 * @title A multi-signature safe to secure digital assets.
 * @author Ricardo Passos - @ricardo-passos
 */
contract SmartSafe is
    Initializable,
    ReentrancyGuard,
    OwnerManager,
    TransactionManager,
    SignatureManager,
    FallbackManager
{
    error InsufficientBalance();
    error InsufficientSignatures();
    error SignaturesAlreadyCollected();
    error TransactionExecutionFailed(bytes);
    error TransactionNonceError(uint64 required, uint64 received);

    event TransactionExecutionSucceeded(uint64);

    /**
     * @dev
     * - This function essentially initializes a Smart Safe after user
     * deploys a proxy.
     * @notice User can optionally send network native tokens (ETH, BNB, etc).
     */
    function setupOwners(
        address[] memory _owners,
        uint8 _threshold
    ) external payable initializer {
        if (
            _owners.length == 0 ||
            _threshold == 0 ||
            _threshold > _owners.length
        ) {
            revert OwnerManager.OutOfBoundsThreshold();
        }

        OwnerManager.ow_setupOwners(_owners, _threshold);
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
        OwnerManager.isSafeOwner(_transactionProposalSigner);

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

    function executeTransaction(uint64 _transactionNonce) public nonReentrant {
        OwnerManager.isSafeOwner(msg.sender);

        TransactionManager.Transaction
            memory proposedTransaction = TransactionManager
                .getFromTransactionQueue(_transactionNonce);

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

        (bool success, bytes memory data) = proposedTransaction.to.call{
            value: proposedTransaction.value
        }(proposedTransaction.data);

        if (!success && data.length > 0) {
            revert TransactionExecutionFailed(data);
        }

        TransactionManager.requiredTransactionNonce++;
        TransactionManager.increaseExecutedTransactionsSize();
        TransactionManager.moveTransactionFromQueueToHistory(_transactionNonce);

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

        // If there's only one owner, execute the transaction right away;
        // This way users don't need to spend gas with two transactions
        // (proposal + execution);
        if (OwnerManager.threshold == 1) {
            uint64 currentTransactionNonce = TransactionManager
                .transactionNonce - 1;

            executeTransaction(currentTransactionNonce);
        }
    }

    function removeTransaction() public override {
        OwnerManager.isSafeOwner(msg.sender);

        TransactionManager.removeTransaction();
    }

    function addTransactionSignature(
        address _transactionProposalSigner,
        TransactionManager.TransactionApproval _transactionApprovalType,
        bytes memory _transactionProposalSignature
    ) external {
        uint64 requiredTransactionNonce = TransactionManager
            .requiredTransactionNonce;
        uint8 signaturesCount = uint8(
            TransactionManager
                .getFromTransactionQueueSignatures(requiredTransactionNonce)
                .length
        );

        if ((signaturesCount + 1) > OwnerManager.threshold) {
            revert SignaturesAlreadyCollected();
        }

        TransactionManager.Transaction memory transaction = TransactionManager
            .getFromTransactionQueue(requiredTransactionNonce);

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
            TransactionManager.increaseExecutedTransactionsSize();
            TransactionManager.moveTransactionFromQueueToHistory(
                requiredTransactionNonce
            );
        }

        // Automatically execute transaction if approvals are equal to `threshold`
        uint8 approvalsCount = TransactionManager.transactionApprovalsCount[
            requiredTransactionNonce
        ];
        if (approvalsCount == OwnerManager.threshold) {
            executeTransaction(requiredTransactionNonce);
        }
    }
}
