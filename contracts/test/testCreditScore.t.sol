// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CreditScore} from "src/CreditScore.sol";

contract TestCreditScore is Test {
    CreditScore scoreKeeper;

    address public owner = vm.addr(0x100);
    address public lender = vm.addr(0x101);
    address public alice = vm.addr(0x102);
    address public bob = vm.addr(0x103);

    function setUp() public {
        // Deploy the CreditScore contract and initialize it with the owner
        scoreKeeper = new CreditScore();
        scoreKeeper.initialize(owner);

        // Grant Roles
        vm.prank(owner);
        scoreKeeper.addLender(lender);
    }

    function test_AddLender() public {
        vm.startPrank(owner);
        address newLender = vm.addr(0x104);
        scoreKeeper.addLender(newLender);
        vm.stopPrank();
        assertTrue(scoreKeeper.hasRole(scoreKeeper.LENDER_ROLE(), newLender));
    }

    function test_NewCreateUser() public {
        vm.startPrank(lender);
        scoreKeeper.createUser(alice);
        bool userIsActive = scoreKeeper.getActiveUser(alice);
        uint256 score = scoreKeeper.getUserCreditScore(alice);
        vm.stopPrank();

        assertTrue(userIsActive);
        assertEq(score, 300);
    }
}
