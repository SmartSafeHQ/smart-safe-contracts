// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {OwnerManager} from "./OwnerManager.sol";
import {SignatureManager} from "./SignatureManager.sol";
import {TransactionManager} from "./TransactionManager.sol";

contract SmartSafe is
    ReentrancyGuard,
    OwnerManager,
    TransactionManager,
    SignatureManager
{
    error SignaturesAlreadyCollected();
    error TransactionExecutionFailed(bytes);
    error UnsuficientSignatures();

    event TransactionExecutionSucceeded(uint64);

    constructor(address[] memory _owners, uint8 _threshold) {
        OwnerManager.setupOwners(_owners, _threshold);
    }

    modifier checkTransaction(
        address _transactionProposalSigner,
        bytes32 _hashedTransactionProposal,
        bytes memory _transactionProposalSignature
    ) {
        OwnerManager.isSafeOwner(_transactionProposalSigner);

        SignatureManager.checkTransactionSignature(
            _transactionProposalSigner,
            _hashedTransactionProposal,
            _transactionProposalSignature
        );

        _;
    }

    function executeTransaction(
        uint64 _transactionNonce
    ) external nonReentrant {
        TransactionManager.Transaction
            memory proposedTransaction = TransactionManager.getTransaction(
                _transactionNonce
            );

        if (proposedTransaction.signatures.length != OwnerManager.threshold) {
            revert UnsuficientSignatures();
        }

        (bool success, bytes memory data) = proposedTransaction.to.call{
            value: proposedTransaction.value
        }(proposedTransaction.data);

        if (!success && data.length > 0) {
            revert TransactionExecutionFailed(data);
        }

        emit TransactionExecutionSucceeded(_transactionNonce);
    }

    function createTransactionProposal(
        // transaction props
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        // signature
        address _transactionProposalSigner,
        bytes32 _hashedTransactionProposal,
        bytes memory _transactionProposalSignature
    )
        external
        checkTransaction(
            _transactionProposalSigner,
            _hashedTransactionProposal,
            _transactionProposalSignature
        )
    {
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
    )
        external
        checkTransaction(
            _transactionProposalSigner,
            _hashedTransactionProposal,
            _transactionProposalSignature
        )
    {
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
