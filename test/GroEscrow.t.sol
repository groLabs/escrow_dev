// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseFixture.t.sol";
import "../src/common/Errors.sol";

contract TestGroEscrow is BaseFixture {
    function setUp() public override {
        super.setUp();
    }

    function testSimpleDeposit(uint96 depositAmnt) public {
        vm.assume(depositAmnt > 1e6);
        // Give alice some USDC
        vm.startPrank(alice);
        usdc.faucet(depositAmnt);
        uint256 balanceSnapshot = usdc.balanceOf(alice);
        // Approve the escrow to spend USDC
        usdc.approve(address(escrow), depositAmnt);
        // Alice wants to give X USDC to Bob and put it into escrow
        escrow.deposit(address(usdc), bob, depositAmnt, 182 days);
        // Make sure usdc balance decreased:
        assertEq(usdc.balanceOf(alice), balanceSnapshot - depositAmnt);
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

    function testDepositAndClaim(
        uint128 depositAmnt,
        uint224 depositLength
    ) public {
        vm.assume(depositAmnt > 1e6);
        vm.assume(depositLength > 1 minutes);
        // Make new addresses and extract pks
        (address jake, uint256 jakeKey) = makeAddrAndKey("1337");
        vm.label(jake, "Jake");
        (address jill, uint256 jillKey) = makeAddrAndKey("1338");
        vm.label(jill, "Jill");

        uint256 jillBalanceSnapshot = usdc.balanceOf(jill);
        assertEq(jillBalanceSnapshot, 0);
        vm.startPrank(jake);
        usdc.faucet(depositAmnt);
        usdc.approve(address(escrow), depositAmnt);
        // Jake wants to give X USDC to Jill and put it into escrow
        escrow.deposit(address(usdc), jill, depositAmnt, depositLength);
        vm.stopPrank();

        // Time passes and Jill wants to claim his USDC
        vm.warp(block.timestamp + depositLength + 1);
        // Jake signs the claim message
        (uint8 v, bytes32 r, bytes32 s) = signClaimMessage(
            address(usdc),
            jill,
            jake,
            0,
            jakeKey
        );
        // Jill agrees with Jake and signs the claim message as well
        (uint8 v2, bytes32 r2, bytes32 s2) = signClaimMessage(
            address(usdc),
            jill,
            jake,
            0,
            jillKey
        );

        // Encode signatures into messages and append into one bytes array
        bytes memory signatures = packSignatures(v, r, s, v2, r2, s2);
        // Jill wants to claim the USDC after time passed and both parties agreed on the claim
        vm.prank(jill);
        escrow.claim(address(usdc), jill, jake, 0, signatures);
        // Make sure USDC balance increased for Jill
        assertEq(usdc.balanceOf(jill), depositAmnt);

        // Make sure position was claimed
        (bool claimed, , , , ) = escrow.getDeposit(jill, jake, 0);
        assertTrue(claimed);
    }

    function testDepositClaimTooEarly(
        uint128 depositAmnt,
        uint224 depositLength
    ) public {
        vm.assume(depositAmnt > 1e6);
        vm.assume(depositLength > 1 minutes);
        // Make new addresses and extract pks
        (address jake, uint256 jakeKey) = makeAddrAndKey("1337");
        vm.label(jake, "Jake");
        (address jill, uint256 jillKey) = makeAddrAndKey("1338");
        vm.label(jill, "Jill");

        uint256 jillBalanceSnapshot = usdc.balanceOf(jill);
        assertEq(jillBalanceSnapshot, 0);
        vm.startPrank(jake);
        usdc.faucet(depositAmnt);
        usdc.approve(address(escrow), depositAmnt);
        // Jake wants to give X USDC to Jill and put it into escrow
        escrow.deposit(address(usdc), jill, depositAmnt, depositLength);
        vm.stopPrank();

        // Time passes and Jill wants to claim his USDC, but she is too early
        vm.warp(block.timestamp + depositLength - 1);
        // Jake signs the claim message
        (uint8 v, bytes32 r, bytes32 s) = signClaimMessage(
            address(usdc),
            jill,
            jake,
            0,
            jakeKey
        );
        // Jill agrees with Jake and signs the claim message as well
        (uint8 v2, bytes32 r2, bytes32 s2) = signClaimMessage(
            address(usdc),
            jill,
            jake,
            0,
            jillKey
        );
        // Encode signatures into messages and append into one bytes array
        bytes memory signatures = packSignatures(v, r, s, v2, r2, s2);
        // Jill wants to claim the USDC after time passed and both parties agreed on the claim
        // But she is too early and she will get an error
        vm.startPrank(jill);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.TooEarlyToClaim.selector)
        );
        escrow.claim(address(usdc), jill, jake, 0, signatures);
        vm.stopPrank();
    }
}
