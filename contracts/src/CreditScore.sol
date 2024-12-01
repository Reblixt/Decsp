// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract CreditScore is
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    // ================= Type Declarations =================
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LENDER_ROLE = keccak256("BANK_ROLE");

    struct PaymentPlan {
        uint256 interestRate;
        uint256 amount;
        uint256 time;
        uint256 paidDebt;
        uint256 unpaidDebt;
        uint256 totalPaid;
        bool active;
    }

    mapping(address => uint256) private userMeanCreditScores;
    mapping(address => uint256) private userNumberOfCreditScores;
    mapping(address => PaymentPlan[]) public userPaymentPlans;
    mapping(address => mapping(address => bool)) public userApprovedLender;
    mapping(address => mapping(address => uint256))
        public LenderUserCreditScore;

    // ================= State Variables =================
    address[] private activeLenders;

    // ================= Events ==========================
    event LenderAdded(address indexed lender);
    event LenderRemoved(address indexed lender);
    event LenderUpdated(address indexed lender, address indexed newLender);
    event PaymentPlanPaid(address indexed taker);
    event CreditScoreCreated(address indexed taker);
    event PaymentPlanCreated(address indexed taker);
    event CreditScoreUpdated(address indexed taker);

    // ================= Errors ==========================

    error UserNotApproved();
    error LenderNotApproved();
    error CreditScoreAlreadyExists();

    function initialize(address owner) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(ADMIN_ROLE, owner);
        PausableUpgradeable.__Pausable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    /** 
      @dev CreditScore ranges between 300 and 850
    */
    function createUser(address taker) external onlyRole(LENDER_ROLE) {
        require(getActiveUser(taker) == false, CreditScoreAlreadyExists());
        LenderUserCreditScore[msg.sender][taker] = 300;
    }

    function createPaymentPlan(
        address taker,
        uint256 amount,
        uint256 time,
        uint256 interest
    ) external onlyRole(LENDER_ROLE) {
        // checks if the taker has a credit score
        // create a new payment plan for the taker
        // set the amount, time, interest, paidDebt, debt, totalPaid
    }

    function getActiveNumberOfPaymentPlans(
        address taker
    ) public pure returns (uint256) {
        // checks if the taker has a credit score
        // returns the number of payment plans the taker has
    }

    function getTotalUnpaidDebt(address taker) public pure returns (uint256) {
        // checks if the taker has a credit score
        // returns the total unpaid debt of the taker
    }

    // =================== User Functions =======================
    function approveLender(address lender) public {
        // checks if the taker has a credit score
        // checks if the lender has a credit score
        // checks if the lender is not already approved
        // approves the lender
    }

    //==================== Lender Functions ====================

    function payLoanPlusInterest(uint256 amount) public {
        // checks if the taker has payed within the paymentplan give + score else - score
        // if the whole debt is paid, the payment plan is set to inactive
    }

    // ================= Admin Functions ====================
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function addLender(address lender) external onlyRole(ADMIN_ROLE) {
        grantRole(LENDER_ROLE, lender);
        activeLenders.push(lender);
        emit LenderAdded(lender);
    }

    /** @dev If there is to many lenders this function no longer works because of hitting
     * the Gas limit of a single transaction.
     * if that is the case, we need to upgrade this contract and remove the foor loop.
     */
    function removeLender(address lender) external onlyRole(ADMIN_ROLE) {
        revokeRole(LENDER_ROLE, lender);
        for (uint256 i = 0; i < activeLenders.length; i++) {
            if (activeLenders[i] == lender) {
                activeLenders[i] = activeLenders[activeLenders.length - 1];
                activeLenders.pop();
                break;
            }
        }
        emit LenderRemoved(lender);
    }

    /** @dev If there is to many lenders this function no longer works because of hitting
     * the Gas limit of a single transaction.
     * if that is the case, we need to upgrade this contract and remove the foor loop
     */
    function updateLender(
        address oldLender,
        address newLender
    ) external onlyRole(ADMIN_ROLE) {
        revokeRole(LENDER_ROLE, oldLender);
        grantRole(LENDER_ROLE, newLender);
        for (uint256 i = 0; i < activeLenders.length; i++) {
            if (activeLenders[i] == oldLender) {
                activeLenders[i] = newLender;
                break;
            }
        }
        emit LenderUpdated(oldLender, newLender);
    }

    // ================= Getter Functions ======================
    function getActiveUser(
        address taker
    ) public view onlyRole(LENDER_ROLE) returns (bool) {
        address lender = msg.sender;
        bool active = (LenderUserCreditScore[lender][taker] != 0);
        return active;
    }

    function getUserCreditScore(
        address taker
    ) public view returns (uint256 score) {
        score = LenderUserCreditScore[msg.sender][taker];
    }

    function meanCreditScore(address taker) public view returns (uint256) {
        return userMeanCreditScores[taker];
    }

    // ================= Internal Functions ====================
    function updateCreditScore() internal {}
}
