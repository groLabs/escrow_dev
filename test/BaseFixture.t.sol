// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "./Utils.sol";
import "../src/GroEscrow.sol";
import "../src/mocks/MockUSDC.sol";

contract BaseFixture is Test {
    using stdStorage for StdStorage;
    Utils internal utils;
    address payable[] internal users;

    address internal alice;
    address internal bob;
    address internal joe;

    GroEscrow public escrow;
    MockUSDC public usdc;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(5);
        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
        joe = users[2];
        vm.label(joe, "Joe");
        // Deploy escrow:
        escrow = new GroEscrow();
        // Deploy escrow token:
        usdc = new MockUSDC();
    }

    function signClaimMessage(
        address token,
        address payee,
        address payer,
        uint256 nonce,
        uint256 pkey
    ) public returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 domainSeparator = keccak256(
            abi.encode(escrow.DOMAIN_TYPEHASH(), block.chainid, address(escrow))
        );
        bytes32 structHash = keccak256(
            abi.encode(escrow.CLAIM_TYPEHASH(), token, payee, payer, nonce)
        );
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        (v, r, s) = vm.sign(pkey, messageHash);
        assertTrue(
            payee == ecrecover(messageHash, v, r, s) ||
                payer == ecrecover(messageHash, v, r, s)
        );
        return (v, r, s);
    }

    function packSignatures(
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) public pure returns (bytes memory) {
        // Combine signatures using abi.encodePacked
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);

        return abi.encodePacked(signature1, signature2);
    }
}
