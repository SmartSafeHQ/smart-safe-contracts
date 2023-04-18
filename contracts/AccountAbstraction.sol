// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AccountAbstraction {
    struct UserOperation {
        address callee;
        address recipient;
        uint256 amount;
    }

    struct Authorization {
        bool isAuthorized;
        address userAddress;
        address tokenAddress;
        uint32 authorizationIndex;
        uint256 tokenAmount;
        uint256 startDate;
    }

    struct AuthorizationPayload {
        address userAddress;
        address tokenAddress;
        uint256 tokenAmount;
        uint256 startDate;
    }

    address public immutable owner;

    mapping(address => uint32) public totalAuthorizationsPerAddress;
    mapping(uint32 => Authorization) public authorizations;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "[Account]: Caller is not the owner.");

        _;
    }

    modifier onlyAuthorizedUsers(address userAddress) {
        uint32 autorizationIndex = totalAuthorizationsPerAddress[userAddress];

        require(
            msg.sender == owner ||
                authorizations[autorizationIndex - 1].isAuthorized,
            "[Account#onlyAuthorizedUsers]: User address not authorized."
        );

        _;
    }

    function executeOp(
        UserOperation memory authorizationPayload
    ) external onlyAuthorizedUsers(authorizationPayload.recipient) {
        /**
            The AA owner is not included in the `authorizedUsers` mapping;
            Thus, this check should only be performed for addresses other than the owner's address;
        **/
        if (msg.sender != owner) {
            uint32 authorizationIndex = totalAuthorizationsPerAddress[
                authorizationPayload.recipient
            ];
            Authorization memory authorization = authorizations[
                authorizationIndex - 1
            ];

            require(
                authorizationPayload.amount <= authorization.tokenAmount,
                "[Account#executeOp]: User is trying to withdraw more than was allowed."
            );
        }

        bytes memory callData = abi.encodeWithSignature(
            "transfer(address,uint256)",
            authorizationPayload.recipient,
            authorizationPayload.amount
        );

        (bool success, ) = authorizationPayload.callee.call(callData);

        require(success, "[Account#executeOp]: Function call failed.");

        if (msg.sender != owner) {
            uint32 authorizationIndex = totalAuthorizationsPerAddress[
                authorizationPayload.recipient
            ];
            Authorization storage authorization = authorizations[
                authorizationIndex - 1
            ];

            authorization.tokenAmount -= authorizationPayload.amount;
        }
    }

    function addAuhtorizedUser(
        AuthorizationPayload memory authorizationPayload
    ) external onlyOwner {
        Authorization memory authorization = Authorization({
            isAuthorized: true,
            userAddress: authorizationPayload.userAddress,
            tokenAddress: authorizationPayload.tokenAddress,
            authorizationIndex: totalAuthorizationsPerAddress[
                authorizationPayload.userAddress
            ],
            tokenAmount: authorizationPayload.tokenAmount,
            startDate: authorizationPayload.startDate
        });

        uint32 totalAuthorizations = totalAuthorizationsPerAddress[
            authorizationPayload.userAddress
        ];
        authorizations[totalAuthorizations] = authorization;
        totalAuthorizationsPerAddress[authorizationPayload.userAddress] =
            totalAuthorizations +
            1;
    }

    function removeAuthorizedUser(
        uint32 authorizationIndex
    ) external onlyOwner {
        delete authorizations[authorizationIndex];
    }
}
