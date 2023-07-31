// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./BaseFixture.t.sol";
import "../src/common/Errors.sol";

contract TestArbiters is BaseFixture {
    function setUp() public override {
        super.setUp();
    }

    //////////////////////////////////////////////////////////////////////////////
    ///////                       Admin functions tests                    ///////
    //////////////////////////////////////////////////////////////////////////////
    function testCanAddArbiter() public {
        assertEq(escrow.getArbiters().length, 0);
        escrow.addArbiter(alice);
        assertEq(escrow.getArbiters().length, 1);
    }

    function testCanAddAndRemoveArbiter() public {
        assertEq(escrow.getArbiters().length, 0);
        escrow.addArbiter(alice);
        assertEq(escrow.getArbiters()[0], address(alice));
        escrow.removeArbiter(alice);
        assertEq(escrow.getArbiters()[0], address(0));
    }

    function testCantAddSameArbiterTwice() public {
        escrow.addArbiter(alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadyArbiter.selector));
        escrow.addArbiter(alice);
    }

    function testCantAddArbiter() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        escrow.addArbiter(alice);
        vm.stopPrank;
    }
}
