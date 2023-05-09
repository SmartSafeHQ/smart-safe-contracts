// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TransactionManager {
    uint64 public transactionNonce = 0;

    event TransactionProposalCreated(uint64 indexed);
    event TransactionSignatureAdded(uint64 indexed);

    struct Transaction {
        address from;
        address to;
        uint256 value;
        bytes data;
        bytes[] signatures;
    }

    mapping(uint64 => Transaction) private transactions;

    function getTransaction(
        uint64 _transactionNonce
    ) internal view returns (Transaction memory) {
        return transactions[_transactionNonce];
    }

    function getTransactionSignatures(
        uint64 _transactionNonce
    ) public view returns (bytes[] memory) {
        return transactions[_transactionNonce].signatures;
    }

    function tm_createTransactionProposal(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes memory _signature
    ) internal {
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = _signature;

        Transaction memory transactionProposal = Transaction({
            from: _from,
            to: _to,
            value: _value,
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
        bytes memory _signature
    ) internal {
        transactions[_transactionNonce].signatures.push(_signature);

        emit TransactionSignatureAdded(_transactionNonce);
    }
}
