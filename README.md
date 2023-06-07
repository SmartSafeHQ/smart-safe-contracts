# Smart Safe

Smart Safe is a multi-signature vault. The entry point is `SmartSafeProxyFactory.sol`. It uses the EIP-1167 so that users only pay for deploying a Proxy contract that interacts with the Smart Safe implementation.

## Getting started

Your first deploy the `src/core/SmartSafe.sol` contract.
Second, you deploy the `src/proxy/SmartSafeProxyFactory.sol` and call `deploySmartSafeProxy`. This function will initialize a SmartSafe for the given `_owners` parameter.

From now on, the user will interact with the smart contract deployed by the `deploySmartSafeProxy` function.

## Credits

Some features were inspired on Gnosis Safe source code.
