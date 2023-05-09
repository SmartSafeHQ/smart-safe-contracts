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
        address _signer,
        bytes32 _hashedTransactionProposal,
        bytes memory _signature
    ) {
        OwnerManager.isSafeOwner(_signer);

        SignatureManager.checkTransactionSignature(
            _signer,
            _hashedTransactionProposal,
            _signature
        );

        _;
    }

    function executeTransaction(
        uint64 _transactionNonce
    ) external nonReentrant {
        TransactionManager.Transaction memory transaction = TransactionManager
            .getTransaction(_transactionNonce);

        if (transaction.signatures.length != OwnerManager.threshold) {
            revert UnsuficientSignatures();
        }

        (bool success, bytes memory data) = transaction.to.call{
            value: transaction.value
        }(transaction.data);

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
        address _signer,
        bytes32 _hashedTransactionProposal,
        bytes memory _signature
    )
        external
        checkTransaction(_signer, _hashedTransactionProposal, _signature)
    {
        TransactionManager.tm_createTransactionProposal(
            _from,
            _to,
            _value,
            _data,
            _signature
        );
    }

    function addTransactionSignature(
        uint64 _transactionNonce,
        address _signer,
        bytes32 _hashedTransactionProposal,
        bytes memory _signature
    )
        external
        checkTransaction(_signer, _hashedTransactionProposal, _signature)
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
            _signature
        );
    }
}
