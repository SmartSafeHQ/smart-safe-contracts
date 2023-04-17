// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Account {
    struct UserOperation {
        address callee;
        address recipient;
        uint256 amount;
    }

    struct AuthorizedUser {
        bool isAuthorized;
        address userAddress;
        address tokenAddress;
        uint256 tokenAmount;
        uint256 startDate;
    }

    address public immutable owner;

    mapping(address => AuthorizedUser) private authorizedUsers;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Account: Caller is not the owner.");

        _;
    }

    modifier onlyAuthorizedUsers(address recipient) {
        require(
            msg.sender == owner || authorizedUsers[recipient].isAuthorized,
            "Account: User address not authorized."
        );

        _;
    }

    function executeOp(UserOperation memory userOperationPayload)
        external
        onlyAuthorizedUsers(userOperationPayload.recipient)
    {
        /**
            The AA owner is not included in the `authorizedUsers` mapping;
            Thus, this check should only be performed for addresses other than the owner's address;
        **/
        if (msg.sender != owner) {
            AuthorizedUser memory authorizedUser = authorizedUsers[
                userOperationPayload.recipient
            ];

            require(
                userOperationPayload.amount <= authorizedUser.tokenAmount,
                "Account: User is trying to withdraw more than was allowed."
            );
        }

        bytes memory callData = abi.encodeWithSignature(
            "transfer(address,uint256)",
            userOperationPayload.recipient,
            userOperationPayload.amount
        );

        (bool success, ) = userOperationPayload.callee.call(callData);

        require(success, "[Account]: Function call failed.");
    }

    function addAuhtorizedUser(AuthorizedUser memory authorizedUserPayload)
        external
        onlyOwner
    {
        AuthorizedUser memory authorizedUser = authorizedUserPayload;

        authorizedUsers[authorizedUserPayload.userAddress] = authorizedUser;
    }
}
