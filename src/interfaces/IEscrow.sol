// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEscrow {
    function addArbiter(address arbiter) external;

    function removeArbiter(address arbiter) external;

    function getArbiters() external view returns (address[] memory);

    function deposit(
        address token,
        address payee,
        uint256 amount,
        uint256 length
    ) external returns (bytes32);

    function claim(
        address token,
        address payee,
        address payer,
        uint256 nonce,
        bytes memory signatures
    ) external;

    function getDeposit(
        address payee,
        address payer,
        uint256 nonce
    )
        external
        view
        returns (
            bool claimed,
            address token,
            uint256 amount,
            uint256 start,
            uint256 length
        );

    function hashEscrowPosition(
        address payee,
        address payer,
        uint256 nonce
    ) external pure returns (bytes32);
}
