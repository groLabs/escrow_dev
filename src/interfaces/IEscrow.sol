// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEscrow {
    function deposit(
        address token,
        address payee,
        uint256 amount,
        uint256 length
    ) external returns (bytes32);
}
