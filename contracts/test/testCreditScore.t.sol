// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CreditScore} from "src/CreditScore.sol";

//TODO: Add more tests to test if the credit score increase, decrease etc
//TODO: Add more test to test Reverts

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

  function test_GetMyCreditScore() public {
    vm.prank(bob);
    scoreKeeper.approveLender(lender);

    vm.prank(lender);
    scoreKeeper.newClient(bob);

    vm.prank(bob);
    uint256 score = scoreKeeper.getMyCreditScore(lender);

    assertEq(score, 300);
  }

  function test_ApproveNewPaymentPlan() public {
    vm.prank(bob);
    scoreKeeper.approveLender(lender);
    uint256 Id = Helper_createPaymentPlan(bob);

    vm.startPrank(bob);
    scoreKeeper.approveNewPaymentPlan(Id);
    (bool isActive, , , , , , ) = scoreKeeper.getPaymentPlan(Id);
    vm.stopPrank();
    assertTrue(isActive);
  }

  function test_GetAllMyPayments() public {
    uint256 Id = Helper_createPaymentPlan(alice);
    uint256 id2 = Helper_createPaymentPlan(alice);
    vm.startPrank(alice);
    scoreKeeper.approveLender(lender);
    scoreKeeper.approveNewPaymentPlan(Id);
    scoreKeeper.approveNewPaymentPlan(id2);
    vm.stopPrank();

    vm.startPrank(lender);
    scoreKeeper.payment(20e18, Id);
    vm.stopPrank();

    vm.startPrank(alice);
    (
      bool[] memory actives,
      uint256[] memory Deadlines,
      uint256[] memory paidAmounts,
      uint256[] memory unpaidAmounts,
      uint256[] memory totalPaids,
      uint32[] memory numInstallments,
      uint16[] memory interestRate
    ) = scoreKeeper.getAllMyPaymentPlans();
    vm.stopPrank();
    // console.log("actives", actives[0]);
    assertEq(actives[0], true);
    assertEq(Deadlines[0], block.timestamp + 30 days * 5);
    assertEq(paidAmounts[0], 20e18);
    assertEq(unpaidAmounts[0], 80e18);
    assertEq(totalPaids[0], 20e18);
    assertEq(numInstallments[0], 4);
    assertEq(interestRate[0], 100);
    assertEq(actives[1], true);
    assertEq(Deadlines[1], block.timestamp + 30 days * 5);
    assertEq(paidAmounts[1], 0);
    assertEq(unpaidAmounts[1], 100e18);
    assertEq(totalPaids[1], 0);
    assertEq(numInstallments[1], 5);
    assertEq(interestRate[1], 100);
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
    uint256 Id = Helper_createPaymentPlan(alice);
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
    assertEq(Deadline + 1, block.timestamp + 30 days * 5);
    assertEq(paidAmount, 0);
    assertEq(unpaidAmount, 100e18);
    assertEq(totalPaid, 0);
    assertEq(numInstallments, 5);
    assertEq(interestRate, 100);
  }

  function test_GetActiveNumberOfPaymentPlans() public {
    uint256 Id1 = Helper_createPaymentPlan(alice);
    uint256 Id2 = Helper_createPaymentPlan(alice);
    uint256 Id3 = Helper_createPaymentPlan(alice);
    vm.startPrank(alice);
    scoreKeeper.approveNewPaymentPlan(Id1);
    scoreKeeper.approveNewPaymentPlan(Id2);
    scoreKeeper.approveNewPaymentPlan(Id3);
    vm.stopPrank();

    vm.startPrank(lender);
    uint256 activePlans = scoreKeeper.getActiveNumberOfPaymentPlans(alice);
    vm.stopPrank();

    assertEq(activePlans, 3);
  }

  function test_GetNextInsalmentAmount() public {
    uint256 Id = Helper_PrepareUntillPaymentFunction(bob);
    uint256 nextInstallment = scoreKeeper.getNextInstalmentAmount(Id);
    // 20 * 100 / 5 = 20
    assertEq(nextInstallment, 20e18);
  }

  function test_GetNextInsalmentDeadline() public {
    uint256 Id = Helper_PrepareUntillPaymentFunction(bob);
    uint256 nextDeadline = scoreKeeper.getNextInstalmentDeadline(Id);
    assertEq(nextDeadline, block.timestamp + 30 days);
  }

  function test_GetTimeBetweenInstallments() public {
    uint256 Id = Helper_PrepareUntillPaymentFunction(bob);
    uint256 timeBetweenInstallments = scoreKeeper.getTimeBetweenInstalment(Id);
    assertEq(timeBetweenInstallments, 30 days);
  }

  function test_IsLenderApprovedByUser() public {
    vm.prank(lender);
    bool isFalse = scoreKeeper.isLenderApprovedByUser(charlie, lender);
    assertEq(isFalse, false);
    bool isTrue = scoreKeeper.isLenderApprovedByUser(alice, lender);
    assertEq(isTrue, true);
  }

  function test_IsInstalmentOnTime() public {
    uint256 Id = Helper_PrepareUntillPaymentFunction(bob);
    vm.warp(block.timestamp + 62 days);
    bool onTime = scoreKeeper.isInstalmentOnTime(Id);
    assertFalse(onTime);
    uint256 Id2 = Helper_PrepareUntillPaymentFunction(charlie);
    vm.warp(block.timestamp + 20 days);
    bool onTime2 = scoreKeeper.isInstalmentOnTime(Id2);
    assertTrue(onTime2);
  }

  function test_IsInstalmentSufficient() public {
    uint256 Id = Helper_PrepareUntillPaymentFunction(bob);
    bool sufficient1 = scoreKeeper.isInstalmentSufficient(Id, 10e18);
    assertFalse(sufficient1);
    bool sufficient2 = scoreKeeper.isInstalmentSufficient(Id, 20e18);
    assertTrue(sufficient2);
  }

  function test_PayInstallment() public {
    uint256 Id = Helper_createPaymentPlan(alice);
    vm.startPrank(alice);
    scoreKeeper.approveLender(lender);
    scoreKeeper.approveNewPaymentPlan(Id);
    vm.stopPrank();

    vm.startPrank(lender);
    scoreKeeper.payment(20e18, Id);
    (, , , uint256 unpaidAmount, uint256 totalPaid, , ) = scoreKeeper
      .getPaymentPlan(Id);
    vm.stopPrank();

    assertEq(unpaidAmount, 80e18);
    assertEq(totalPaid, 20e18);
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

  function test_GetActiveLenders() public {
    address newLender = vm.addr(0x202);
    address newLender2 = vm.addr(0x203);
    vm.startPrank(owner);
    scoreKeeper.addLender(newLender);
    scoreKeeper.addLender(newLender2);

    address[] memory activeLenders = scoreKeeper.getActiveLenders();
    vm.stopPrank();

    assertEq(activeLenders.length, 3);
    assertEq(activeLenders[0], lender);
    assertEq(activeLenders[1], newLender);
    assertEq(activeLenders[2], newLender2);
  }

  // ------Reverts------

  // =============== Helper Funcitons ===============
  function Helper_createPaymentPlan(address client) public returns (uint256) {
    vm.startPrank(lender);
    uint256 deadline = 30 days * 5;
    uint256 amountToLend = 100e18;
    uint256 Id = scoreKeeper.createPaymentPlan(
      client,
      amountToLend,
      deadline,
      5,
      100
    );
    vm.stopPrank();
    return Id;
  }

  function Helper_PrepareUntillPaymentFunction(
    address client
  ) public returns (uint256) {
    vm.prank(client);
    scoreKeeper.approveLender(lender);
    uint256 Id = Helper_createPaymentPlan(client);
    vm.prank(client);
    scoreKeeper.approveNewPaymentPlan(Id);

    return Id;
  }
}
