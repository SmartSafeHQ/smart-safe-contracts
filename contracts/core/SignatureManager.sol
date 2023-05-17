// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @author Ricardo Passos - @ricardo-passos
 */
contract SignatureManager is EIP712 {
    error InvalidSigner();
    error InvalidTransactionHash();

    struct Signature {
        address from;
        address to;
        uint64 transactionNonce;
        uint256 value;
        bytes data;
    }

    // keccak256(Signature(address,address,uint64,uint256,bytes))
    bytes32 private constant HASHED_SIGNATURE_STRUCT =
        0x75dd892ed6904a270511ac2b8413835fc5603972d6a9c9b9adf74f09486255eb;

    constructor() EIP712("Smart Safe Signature Manager", "1.0.0") {}

    function checkTransactionSignature(
        // transaction related
        address _from,
        address _to,
        uint64 _transactionNonce,
        uint256 _value,
        bytes memory _data,
        // signature related
        address _signer,
        bytes32 _hashedTransactionProposal,
        bytes memory _transactionProposalSignature
    ) internal view returns (address) {
        bytes32 transactionHash = computeTransactionHash(
            _from,
            _to,
            _transactionNonce,
            _value,
            _data
        );

        if (transactionHash != _hashedTransactionProposal) {
            revert InvalidTransactionHash();
        }

        address transactionSigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(_hashedTransactionProposal),
            _transactionProposalSignature
        );

        if (_signer != transactionSigner) {
            revert InvalidSigner();
        }

        return transactionSigner;
    }

    function computeTransactionHash(
        address _from,
        address _to,
        uint64 _transactionNonce,
        uint256 _value,
        bytes memory _data
    ) public view returns (bytes32) {
        bytes memory encodedStruct = abi.encode(
            HASHED_SIGNATURE_STRUCT,
            _from,
            _to,
            _transactionNonce,
            _value,
            keccak256(_data)
        );

        bytes32 hashedEncodedStruct = keccak256(encodedStruct);

        bytes32 typedData = EIP712._hashTypedDataV4(hashedEncodedStruct);

        return typedData;
    }
}
