// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract SignatureManager is EIP712 {
    struct Signature {
        address to;
        address from;
        uint256 value;
        uint64 transactionNonce;
    }

    constructor() EIP712("Smart Safe Signature Manager", "1.0.0") {}

    function checkTransactionSignature(
        address _signer,
        bytes32 _hashedTransactionProposal,
        bytes memory _signature
    ) internal pure returns (address) {
        address transactionSigner = ECDSA.recover(
            _hashedTransactionProposal,
            _signature
        );

        require(
            _signer == transactionSigner,
            "[SignatureManager#checkTransactionSignature]: invalid transaction signer."
        );

        return transactionSigner;
    }
}
