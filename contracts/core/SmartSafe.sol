// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {OwnerManager} from "./OwnerManager.sol";
import {FallbackManager} from "./FallbackManager.sol";
import {SignatureManager} from "./SignatureManager.sol";
import {TransactionManager} from "./TransactionManager.sol";

contract SmartSafe is
    ReentrancyGuard,
    OwnerManager,
    TransactionManager,
    SignatureManager,
    FallbackManager
{
    error UnsufficientSignatures();
    error SignaturesAlreadyCollected();
    error TransactionExecutionFailed(bytes);
    error TransactionNonceError(uint64 required, uint64 received);

    event TransactionExecutionSucceeded(uint64);

    constructor(address[] memory _owners, uint8 _threshold) {
        OwnerManager.setupOwners(_owners, _threshold);
    }

    // Although using the `modifier` keyword would be considered more semantic,
    // it increases the final code bytecode. Using a function is cheaper.
    // By doing this simple modification, it has reduced the final bytecode in 2kb.
    function checkTransaction(
        address _transactionProposalSigner,
        bytes32 _hashedTransactionProposal,
        bytes memory _transactionProposalSignature
    ) private view {
        OwnerManager.isSafeOwner(_transactionProposalSigner);

        SignatureManager.checkTransactionSignature(
            _transactionProposalSigner,
            _hashedTransactionProposal,
            _transactionProposalSignature
        );
    }

    function executeTransaction(
        uint64 _transactionNonce
    ) external nonReentrant {
        OwnerManager.isSafeOwner(msg.sender);

        TransactionManager.Transaction
            storage proposedTransaction = TransactionManager.getTransaction(
                _transactionNonce
            );

        // By requiring that the `proposedTransactionNonce` is equal to
        // the latest proposed transaction `requiredTransactionNonce` we ensure
        // all transactions follow a linear order of execution.
        uint64 requiredTransactionNonce = (TransactionManager.transactionNonce -
            1);
        uint64 proposedTransactionNonce = proposedTransaction.transactionNonce;
        if (!(proposedTransactionNonce == requiredTransactionNonce)) {
            revert TransactionNonceError(
                requiredTransactionNonce,
                proposedTransactionNonce
            );
        }

        if (
            !(proposedTransaction.signatures.length >= OwnerManager.threshold)
        ) {
            revert UnsufficientSignatures();
        }

        (bool success, bytes memory data) = proposedTransaction.to.call{
            value: proposedTransaction.value
        }(proposedTransaction.data);

        if (!success && data.length > 0) {
            revert TransactionExecutionFailed(data);
        }

        proposedTransaction.isActive = false;

        emit TransactionExecutionSucceeded(_transactionNonce);
    }

    function createTransactionProposal(
        // transaction related
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        // signature related
        address _transactionProposalSigner,
        bytes32 _hashedTransactionProposal,
        bytes memory _transactionProposalSignature
    ) external {
        checkTransaction(
            _transactionProposalSigner,
            _hashedTransactionProposal,
            _transactionProposalSignature
        );

        TransactionManager.tm_createTransactionProposal(
            _from,
            _to,
            _value,
            _data,
            _transactionProposalSignature
        );
    }

    function addTransactionSignature(
        uint64 _transactionNonce,
        address _transactionProposalSigner,
        bytes32 _hashedTransactionProposal,
        bytes memory _transactionProposalSignature
    ) external {
        checkTransaction(
            _transactionProposalSigner,
            _hashedTransactionProposal,
            _transactionProposalSignature
        );

        uint8 signaturesCount = uint8(
            TransactionManager
                .getTransactionSignatures(_transactionNonce)
                .length
        );

        if ((signaturesCount + 1) > OwnerManager.threshold) {
            revert SignaturesAlreadyCollected();
        }

        TransactionManager.tm_addTransactionSignature(
            _transactionNonce,
            _transactionProposalSignature
        );
    }
}
