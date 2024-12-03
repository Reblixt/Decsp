// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CreditScore} from "src/CreditScore.sol";

contract TestCreditScore is Test {
  CreditScore scoreKeeper;

  address public owner = vm.addr(0x100);
  address public lender = vm.addr(0x201);
  address public alice = vm.addr(0x102);
  address public bob = vm.addr(0x103);
  address public charlie = vm.addr(0x104);

  function setUp() public {
    // Deploy the CreditScore contract and initialize it with the owner
    scoreKeeper = new CreditScore();
    scoreKeeper.initialize(owner);

    // Grant Roles to Lender
    vm.prank(owner);
    scoreKeeper.addLender(lender);

    // Approve Lender
    vm.startPrank(alice);
    scoreKeeper.newProfile();
    scoreKeeper.approveLender(lender);
    vm.stopPrank();
    // Lender creates a new client
    vm.prank(lender);
    scoreKeeper.newClient(alice);
  }

  // ================ User Functions ================
  function test_createNewProfile() public {
    vm.prank(bob);
    scoreKeeper.newProfile();
  }

  function test_ApproveLender() public {
    vm.prank(alice);
    scoreKeeper.approveLender(lender);

    assertTrue(scoreKeeper.isLenderClient(lender));
  }

  // ------Reverts------
  function test_RevertWhenProfileAlreadyExists() public {
    vm.expectRevert(CreditScore.ProfileAlreadyExists.selector);
    vm.prank(alice);
    scoreKeeper.newProfile();
  }

  function test_RevertWhenLenderIsNotClient() public {
    vm.expectRevert(CreditScore.LenderIsNotClient.selector);
    vm.prank(alice);
    scoreKeeper.approveLender(bob);
  }

  // ================ Lender Functions ================

  function test_NewClient() public {
    vm.startPrank(bob);
    scoreKeeper.newProfile();
    scoreKeeper.approveLender(lender);
    vm.stopPrank();

    vm.startPrank(lender);
    scoreKeeper.newClient(bob);
    bool userIsActive = scoreKeeper.isActiveUser(bob);
    uint256 score = scoreKeeper.getUserCreditScore(bob);
    vm.stopPrank();

    assertTrue(userIsActive);
    assertEq(score, 300);
  }

  function test_GetTotalUnpaidDept() public {
    vm.startPrank(lender);
    scoreKeeper.createPaymentPlan(alice, 100, 10, 10);
    uint256 unpaidDept = scoreKeeper.getTotalUnpaidDebt(alice);
    vm.stopPrank();

    assertEq(unpaidDept, 0);
  }

  // ------Reverts------

  function test_RevertWhenUserAlreadyExists() public {
    vm.expectRevert(CreditScore.CreditScoreAlreadyExists.selector);
    vm.prank(lender);
    scoreKeeper.newClient(alice);
  }

  function test_RevertWhenLenderNotApprovedByUser() public {
    vm.prank(charlie);
    scoreKeeper.newProfile();
    vm.expectRevert(CreditScore.LenderNotApproved.selector);
    vm.prank(lender);
    scoreKeeper.newClient(charlie);
  }

  // ================ Admin Functions ================

  function test_AddLender() public {
    vm.startPrank(owner);
    address newLender = vm.addr(0x202);
    scoreKeeper.addLender(newLender);
    vm.stopPrank();

    assertTrue(scoreKeeper.hasRole(scoreKeeper.LENDER_ROLE(), newLender));
    assertEq(scoreKeeper.isLenderClient(newLender), true);
  }

  function test_RemoveLender() public {
    vm.startPrank(owner);
    scoreKeeper.removeLender(lender);
    vm.stopPrank();
    assertTrue(scoreKeeper.isLenderClient(lender) == false);
  }

  function test_updateLender() public {
    vm.startPrank(owner);
    address newLender = vm.addr(0x202);
    scoreKeeper.updateLender(lender, newLender);
    vm.stopPrank();

    assertTrue(scoreKeeper.isLenderClient(newLender));
    assertTrue(scoreKeeper.isLenderClient(lender) == false);
  }

  function test_Pause() public {
    vm.startPrank(owner);
    scoreKeeper.pause();
    vm.stopPrank();
    assertTrue(scoreKeeper.paused());
  }

  function test_Unpause() public {
    test_Pause();
    vm.startPrank(owner);
    scoreKeeper.unpause();
    vm.stopPrank();
    assertTrue(scoreKeeper.paused() == false);
  }

  // ------Reverts------
}
