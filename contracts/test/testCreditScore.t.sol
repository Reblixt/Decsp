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
    bool userIsActive = scoreKeeper.isClientActive(bob);
    uint256 score = scoreKeeper.getUserCreditScore(bob);
    vm.stopPrank();

    assertTrue(userIsActive);
    assertEq(score, 300);
  }

  function test_GetTotalUnpaidDept() public {
    vm.startPrank(lender);
    uint256 unpaidDept = scoreKeeper.getTotalUnpaidDebt(alice);
    vm.stopPrank();

    assertEq(unpaidDept, 0);
  }

  function test_GetMeanCreditScore() public {
    vm.prank(bob);
    scoreKeeper.approveLender(lender);
    vm.startPrank(lender);
    scoreKeeper.newClient(bob);
    uint256 meanScore = scoreKeeper.getMeanCreditScore(bob);
    vm.stopPrank();

    assertEq(meanScore, 300);
  }

  function test_createPaymentPlan() public {
    uint256 Id = Helper_createPaymentPlan();
    vm.prank(lender);
    (
      bool isActive,
      uint256 Deadline,
      uint256 paidAmount,
      uint256 unpaidAmount,
      uint256 totalPaid,
      uint32 numInstallments,
      uint32 interestRate
    ) = scoreKeeper.getPaymentPlan(Id);

    assertFalse(isActive);
    assertEq(Deadline + 1, block.timestamp + 1 days);
    assertEq(paidAmount, 0);
    assertEq(unpaidAmount, 100e18);
    assertEq(totalPaid, 0);
    assertEq(numInstallments, 5);
    assertEq(interestRate, 100);
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

  // =============== Helper Funcitons ===============
  function Helper_createPaymentPlan() public returns (uint256) {
    vm.startPrank(lender);
    uint256 deadline = 1 days;
    uint256 amountToLend = 100e18;
    uint256 Id = scoreKeeper.createPaymentPlan(
      alice,
      amountToLend,
      deadline,
      5,
      100
    );
    vm.stopPrank();
    return Id;
  }
}
