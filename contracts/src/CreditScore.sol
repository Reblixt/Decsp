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
        uint64 interestRate;
        uint256 amount;
        uint256 time;
        uint256 paidDebt;
        uint256 unpaidDebt;
        uint256 totalPaid;
        bool active;
    }

    struct UserProfile {
        mapping(address lender => uint16) creditScore;
        uint16 numberOfCreditScores;
        uint16 numberOfPaymentPlans;
        uint16[] paymentPlanID;
        uint16 meanScore;
        address[] lenders;
        mapping(address lender => bool) approvedLender;
        bool exists;
    }

    mapping(address => UserProfile) private userProfiles;
    mapping(uint256 => PaymentPlan) private paymentPlanID;

    // ================= State Variables =================
    address[] private activeLenders;

    // ================= Events ==========================
    event LenderAdded(address indexed lender);
    event LenderRemoved(address indexed lender);
    event LenderUpdated(address indexed lender, address indexed newLender);

    event PaymentPlanPaid(address indexed taker);
    event PaymentPlanCreated(address indexed taker);

    event CreditScoreCreated(address indexed taker);
    event CreditScoreUpdated(address indexed taker);

    // ================= Errors ==========================

    error NotAuthorized();
    error UserNotApproved();
    error LenderIsNotClient();
    error LenderNotApproved();
    error ProfileDoesNotExist();
    error ProfileAlreadyExists();
    error CreditScoreAlreadyExists();
    error ProfileDoesNotHaveCreditScore();

    function initialize(address owner) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(ADMIN_ROLE, owner);
        PausableUpgradeable.__Pausable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    // =================== User Functions =======================
    /// @dev Creates a new profile for the client/user
    /// @notice This function can only be called once per user
    function newProfile() external {
        require(profileExists(msg.sender) == false, ProfileAlreadyExists());
        userProfiles[msg.sender].exists = true;
    }

    /// @dev User approves a lender to access their credit score
    /// @notice This function also creates a profile for the user if it does not exist
    /// @param lender The address of the lender to approve
    function approveLender(address lender) external {
        // require(profileExists(msg.sender), ProfileDoesNotExist());
        userProfiles[msg.sender].exists = true;
        require(isLenderClient(lender), LenderIsNotClient());
        userProfiles[msg.sender].approvedLender[lender] = true;
    }

    /// @dev User/client can see their credit score from a specific lender
    function getMyCreditScore(
        address lender
    ) public view returns (uint256 score) {
        score = userProfiles[msg.sender].creditScore[lender];
    }

    //==================== Lender Functions ====================

    /** 
      @dev CreditScore ranges between 300 and 850
      @param client The address of the user to create a credit score for
    */
    function newClient(address client) external onlyRole(LENDER_ROLE) {
        require(profileExists(client) == true, ProfileDoesNotExist());
        require(isClientActive(client) == false, CreditScoreAlreadyExists());
        require(
            isLenderApprovedByUser(client, msg.sender),
            LenderNotApproved()
        );
        userProfiles[client].creditScore[msg.sender] = 300;
        userProfiles[client].numberOfCreditScores++;
        userProfiles[client].lenders.push(msg.sender);
    }

    //TODO: Implement the payment function
    function payment(uint256 amount) external nonReentrant {
        // checks if the taker has payed within the paymentplan give + score else - score
        // if the whole debt is paid, the payment plan is set to inactive
    }

    //TODO: Implement the createPaymentPlan function
    function createPaymentPlan(
        address client,
        uint256 amount,
        uint256 time,
        uint256 interest
    ) external onlyRole(LENDER_ROLE) nonReentrant {
        // checks if the taker has a credit score
        // create a new payment plan for the taker
        // set the amount, time, interest, paidDebt, debt, totalPaid
    }

    /// @dev Returns the credit score of a user
    /// @param client The address of the user to get the credit score for
    function getUserCreditScore(
        address client
    ) public view onlyRole(LENDER_ROLE) returns (uint256 score) {
        score = userProfiles[client].creditScore[msg.sender];
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

    function getActiveLenders()
        public
        view
        onlyRole(ADMIN_ROLE)
        returns (address[] memory lenders)
    {
        lenders = activeLenders;
    }

    // ================= Getter Functions ======================

    function getMeanCreditScore(address client) public view returns (uint256) {
        require(
            hasRole(LENDER_ROLE, msg.sender) || msg.sender == client,
            NotAuthorized()
        );
        require(
            isLenderApprovedByUser(client, msg.sender),
            LenderNotApproved()
        );
        address[] memory lenders = userProfiles[client].lenders;
        require(lenders.length > 0, ProfileDoesNotHaveCreditScore());

        uint256 totalScore;
        for (uint256 i = 0; i < lenders.length; i++) {
            totalScore += userProfiles[client].creditScore[lenders[i]];
        }
        return totalScore / lenders.length;
    }

    function getTotalUnpaidDebt(address client) public view returns (uint256) {
        require(
            hasRole(LENDER_ROLE, msg.sender) || msg.sender == client,
            NotAuthorized()
        );
        uint16 numberOfPaymentPlans = userProfiles[client].numberOfPaymentPlans;
        uint16[] memory paymentPlanIds = userProfiles[client].paymentPlanID;
        uint256 totalDebt;
        for (uint16 i = 0; i < numberOfPaymentPlans; i++) {
            totalDebt += paymentPlanID[paymentPlanIds[i]].unpaidDebt;
        }
        return totalDebt;
    }

    function getActiveNumberOfPaymentPlans(
        address client
    ) public view returns (uint16 numberOfPaymentPlans) {
        require(
            hasRole(LENDER_ROLE, msg.sender) || msg.sender == client,
            NotAuthorized()
        );
        numberOfPaymentPlans = userProfiles[client].numberOfPaymentPlans;
    }

    function isClientActive(
        address client
    ) public view onlyRole(LENDER_ROLE) returns (bool) {
        address lender = msg.sender;
        bool active = (userProfiles[client].creditScore[lender] > 0);
        return active;
    }

    function isLenderApprovedByUser(
        address client,
        address lender
    ) public view returns (bool approved) {
        require(
            hasRole(LENDER_ROLE, lender) || msg.sender == client,
            LenderIsNotClient()
        );
        approved = userProfiles[client].approvedLender[lender];
    }

    function isLenderClient(
        address lender
    ) public view returns (bool isClient) {
        isClient = hasRole(LENDER_ROLE, lender);
    }

    // ================= Internal Functions ====================
    //TODO: Implement the updateCreditScore function
    function updateCreditScore() internal {}

    function profileExists(address client) internal view returns (bool exists) {
        exists = userProfiles[client].exists;
    }
}
