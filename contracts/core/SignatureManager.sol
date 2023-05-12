// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract SignatureManager is EIP712 {
    error InvalidSigner();

    struct Signature {
        address to;
        address from;
        uint64 transactionNonce;
        uint256 value;
        bytes data;
    }

    constructor() EIP712("Smart Safe Signature Manager", "1.0.0") {}

    function checkTransactionSignature(
        address _signer,
        bytes32 _hashedTransactionProposal,
        bytes memory _transactionProposalSignature
    ) internal pure returns (address) {
        address transactionSigner = ECDSA.recover(
            _hashedTransactionProposal,
            _transactionProposalSignature
        );

        if (_signer != transactionSigner) {
            revert InvalidSigner();
        }

        return transactionSigner;
    }
}
