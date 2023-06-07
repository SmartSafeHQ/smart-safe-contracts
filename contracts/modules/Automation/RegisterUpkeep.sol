// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AutomationRegistryInterface, State} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        bytes calldata offchainConfig,
        uint96 amount,
        address sender
    ) external;
}

contract RegisterUpkeep {
    struct Params {
        string name;
        bytes encryptedEmail;
        address upkeepContract;
        uint32 gasLimit;
        address adminAddress;
        bytes checkData;
        bytes offchainConfig;
        uint96 amount;
    }

    LinkTokenInterface private immutable linkTokenContract;
    address private immutable registrarContract;
    AutomationRegistryInterface private immutable registryContract;
    bytes4 private registerSig = KeeperRegistrarInterface.register.selector;

    mapping(address => mapping(uint64 => uint256)) public upkeepsPerSmartSafe;

    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry
    ) {
        linkTokenContract = _link;
        registrarContract = _registrar;
        registryContract = _registry;
    }

    function registerAndPredictID(Params memory _params) external {
        (State memory state, , , , ) = registryContract.getState();
        uint256 oldNonce = state.nonce;
        bytes memory payload = abi.encode(
            _params.name,
            _params.encryptedEmail,
            _params.upkeepContract,
            _params.gasLimit,
            _params.adminAddress,
            _params.checkData,
            _params.offchainConfig,
            _params.amount,
            address(this)
        );

        linkTokenContract.transferAndCall(
            registrarContract,
            _params.amount,
            bytes.concat(registerSig, payload)
        );
        (state, , , , ) = registryContract.getState();
        uint256 newNonce = state.nonce;

        if (newNonce == oldNonce + 1) {
            (uint64 transactionNonce, ) = abi.decode(
                _params.checkData,
                (uint64, uint256)
            );

            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(registryContract),
                        uint32(oldNonce)
                    )
                )
            );

            upkeepsPerSmartSafe[_params.upkeepContract][
                transactionNonce
            ] = upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }
}
