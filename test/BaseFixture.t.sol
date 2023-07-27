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
}
