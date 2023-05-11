// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TransactionManager {
    event TransactionSignatureAdded(uint64 indexed);
    event TransactionProposalCreated(uint64 indexed);

    struct Transaction {
        address from;
        address to;
        bool isActive;
        uint64 transactionNonce;
        uint256 value;
        bytes data;
        bytes[] signatures;
    }

    uint64 public transactionNonce = 0;
    mapping(uint64 => Transaction) private transactions;

    function getTransaction(
        uint64 _transactionNonce
    ) internal view returns (Transaction storage) {
        return transactions[_transactionNonce];
    }

    function getTransactionSignatures(
        uint64 _transactionNonce
    ) internal view returns (bytes[] memory) {
        return transactions[_transactionNonce].signatures;
    }

    function tm_createTransactionProposal(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes memory _transactionProposalSignature
    ) internal {
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = _transactionProposalSignature;

        Transaction memory transactionProposal = Transaction({
            from: _from,
            to: _to,
            value: _value,
            transactionNonce: transactionNonce,
            isActive: true,
            data: _data,
            signatures: signatures
        });

        uint64 currentTransactionNonce = transactionNonce;
        transactions[transactionNonce] = transactionProposal;
        transactionNonce++;

        emit TransactionProposalCreated(currentTransactionNonce);
    }

    function tm_addTransactionSignature(
        uint64 _transactionNonce,
        bytes memory _transactionProposalSignature
    ) internal {
        transactions[_transactionNonce].signatures.push(
            _transactionProposalSignature
        );

        emit TransactionSignatureAdded(_transactionNonce);
    }
}
