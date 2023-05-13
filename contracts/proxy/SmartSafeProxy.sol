// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SmartSafeProxy {
    address internal smartSafe;

    constructor(address _smartSafe) {
        require(
            _smartSafe != address(0),
            "[SmartSafeProxy#constructor]: Invalid smart safe address provided."
        );
        smartSafe = _smartSafe;
    }

    fallback(bytes calldata data) external payable returns (bytes memory) {
        (bool ok, bytes memory res) = smartSafe.call{value: msg.value}(data);
        require(ok, "[SmartSafeProxy#fallback]: call failed");
        return res;
    }
}
