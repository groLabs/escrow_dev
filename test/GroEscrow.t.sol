// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseFixture.t.sol";

contract TestGroEscrow is BaseFixture {
    function setUp() public override {
        super.setUp();
    }

    function testSimpleDeposit(uint96 depositAmnt) public {
        vm.assume(depositAmnt > 1e6);
        // Give alice some USDC
        vm.prank(alice);
        usdc.faucet(depositAmnt);
        // Approve the escrow to spend USDC
        vm.startPrank(alice);
        usdc.approve(address(escrow), depositAmnt);
        // Alice wants to give 1000 USDC to Bob and put it into escrow
        escrow.deposit(address(usdc), bob, depositAmnt, 182 days);
        vm.stopPrank();

        // Make sure position was created
        (
            bool claimed,
            address token,
            uint256 amount,
            uint256 start,
            uint256 length
        ) = escrow.getDeposit(bob, alice, 0);
        assertFalse(claimed);
        assertEq(token, address(usdc));
        assertEq(amount, depositAmnt);
        assertEq(start, block.timestamp);
        assertEq(length, 182 days);
    }
}
