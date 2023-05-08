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
        address _to,
        bytes calldata _data,
        uint256 _value,
        bytes memory _signatures
    ) external nonReentrant {
        (bool success, ) = _to.call{value: _value}(_data);

        require(
            success,
            "[SmartSafe#executeTransaction]: function call failed."
        );
    }

    function createTransactionProposal(
        // transaction props
        address _from,
        address _to,
        uint256 _value,
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

        require(
            (signaturesCount + 1) <= threshold,
            "[SmartSafe#addTransactionSignature]: all required signatures already collected."
        );

        TransactionManager.tm_addTransactionSignature(
            _transactionNonce,
            _signature
        );
    }
}
