// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Errors {
    error EscrowClaimedOrDoesntExist();
    error TooEarlyToClaim(); // 0xd71d60b5
    error InvalidSig();

    // Admin
    error AlreadyArbiter();
}
