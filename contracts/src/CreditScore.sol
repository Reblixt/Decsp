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
        address owner;
        bool active;
        uint256 time;
        uint256 lastPayment;
        uint256 paidDebt;
        uint256 unpaidDebt;
        uint256 totalPaid;
        uint32 NumberOfInstalment;
        uint16 interest;
    }

    struct UserProfile {
        bool exists;
        address[] lenders;
        uint16 meanScore;
        uint256[] paymentPlanID;
        uint16 numberOfCreditScores;
        uint16 numberOfPaymentPlans;
        mapping(address lender => uint16) creditScore;
        mapping(address lender => bool) approvedLender;
    }

    mapping(address => UserProfile) private userProfiles;
    mapping(uint256 => PaymentPlan) private paymentPlanID;

    // ================= State Variables =================
    address[] private activeLenders;
    uint256 private paymentPlanCounter;

    // ================= Events ==========================
    event NewProfileCreated(address indexed client);
    event ApprovedLender(address indexed lender);

    event LenderAdded(address indexed lender);
    event LenderRemoved(address indexed lender);
    event LenderUpdated(address indexed lender, address indexed newLender);

    event PaymentPlanPaid(address indexed taker);
    event PaymentPlanCreated(uint256 indexed ID);

    event CreditScoreCreated(address indexed taker);
    event CreditScoreUpdated(address indexed taker);

    // ================= Errors ==========================
    error NonZero();
    error NotActive();
    error AlreadyExists();
    error NotAuthorized();
    error UserNotApproved();
    error LenderIsNotClient();
    error LenderNotApproved();
    error ProfileDoesNotExist();
    error ProfileAlreadyExists();
    error CreditScoreAlreadyExists();
    error PaymentPlanDoNotMatchUser();
    error ProfileDoesNotHaveCreditScore();

    function initialize(address owner) public initializer {
        _grantRole(ADMIN_ROLE, owner);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        PausableUpgradeable.__Pausable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    // =================== User Functions =======================
    /// @dev Creates a new profile for the client/user
    /// @notice This function can only be called once per user
    function newProfile() external whenNotPaused {
        require(profileExists(msg.sender) == false, ProfileAlreadyExists());
        userProfiles[msg.sender].exists = true;
        emit NewProfileCreated(msg.sender);
    }

    /// @dev User approves a lender to access their credit score
    /// @notice This function also creates a profile for the user if it does not exist
    /// @param lender The address of the lender to approve
    function approveLender(address lender) external whenNotPaused {
        userProfiles[msg.sender].exists = true;
        require(isLenderClient(lender), LenderIsNotClient());
        userProfiles[msg.sender].approvedLender[lender] = true;
        emit ApprovedLender(lender);
    }

    /// @dev User/client can see their credit score from a specific lender
    function getMyCreditScore(
        address lender
    ) public view returns (uint256 score) {
        score = userProfiles[msg.sender].creditScore[lender];
    }

    /// @dev User/clinet have to approve the payment plan before it can be used
    /// and attached to the user profile
    /// @param Id The ID of the payment plan to approve
    /// @notice This function can only be called by the owner that intends to accept
    /// the payment plan, and the payment plan must be active, and the user must have
    /// a credit score from the lender that created the payment plan
    function approveNewPaymentPlan(uint256 Id) external whenNotPaused {
        require(
            paymentPlanID[Id].owner == msg.sender,
            PaymentPlanDoNotMatchUser()
        );
        require(paymentPlanID[Id].active == false, NotActive());
        uint256[] memory planID = userProfiles[msg.sender].paymentPlanID;
        for (uint256 i = 0; i < planID.length; i++) {
            if (planID[i] == Id) revert AlreadyExists();
        }
        //// This startes the Payment plan Clock
        paymentPlanID[Id].time = paymentPlanID[Id].time + block.timestamp;
        paymentPlanID[Id].lastPayment = block.timestamp;
        paymentPlanID[Id].active = true;
        userProfiles[msg.sender].numberOfPaymentPlans++;
        userProfiles[msg.sender].paymentPlanID.push(Id);
    }

    //==================== Lender Functions ====================

    /** 
      @dev CreditScore ranges between 300 and 850
      @param client The address of the user to create a credit score for
    */
    function newClient(
        address client
    ) external onlyRole(LENDER_ROLE) whenNotPaused {
        require(profileExists(client) == true, ProfileDoesNotExist());
        require(isClientActive(client) == false, CreditScoreAlreadyExists());
        require(
            isLenderApprovedByUser(client, msg.sender),
            LenderNotApproved()
        );
        userProfiles[client].creditScore[msg.sender] = 300;
        userProfiles[client].numberOfCreditScores++;
        userProfiles[client].lenders.push(msg.sender);

        emit CreditScoreCreated(client);
    }

    /// @dev Should allways be able to be called by the client
    /// @param amount The amount of the payment
    /// @param Id The ID of the payment plan
    function payment(uint256 amount, uint256 Id) external nonReentrant {
        // checks if the taker has payed within the paymentplan give + score else - score
        // if the whole debt is paid, the payment plan is set to inactive
        require(paymentPlanID[Id].active == true, NotActive());
        if (amount > paymentPlanID[Id].unpaidDebt) {
            paymentPlanID[Id].unpaidDebt = 0;
            paymentPlanID[Id].active = false;
        } else {
            paymentPlanID[Id].unpaidDebt -= amount;
            paymentPlanID[Id].totalPaid += amount;
        }
        updateCreditScore(amount, Id);
        emit PaymentPlanPaid(msg.sender);
    }

    /// @dev Choosed delibrately not to include if active paymentPlanID check incase
    /// the lender wants to create multiple payment plans for the same client
    /// This way the Lender and Client can pay off the old loan with a new loan with
    /// a updated terms
    /// @param client The address of the user to create a payment plan for
    /// @param amount The amount of the payment plan
    /// @param time The time the payment plan should be paid back
    /// @param interest The interest rate of the payment plan in percentage where 5& is 500
    function createPaymentPlan(
        address client,
        uint256 amount,
        uint256 time,
        uint32 NumberOfPayments,
        uint256 interest
    )
        external
        onlyRole(LENDER_ROLE)
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        require(
            isLenderApprovedByUser(client, msg.sender),
            LenderNotApproved()
        );
        require(profileExists(client) == true, ProfileDoesNotExist());
        uint256 ID = ++paymentPlanCounter;

        paymentPlanID[ID] = PaymentPlan({
            owner: client,
            active: false,
            time: time,
            lastPayment: 0,
            paidDebt: 0,
            unpaidDebt: amount,
            totalPaid: 0,
            NumberOfInstalment: NumberOfPayments,
            interest: uint16(interest)
        });

        emit PaymentPlanCreated(ID);
        return ID;
    }

    /// @dev Returns the credit score of a user
    /// @param client The address of the user to get the credit score for
    function getUserCreditScore(
        address client
    ) public view onlyRole(LENDER_ROLE) returns (uint256 score) {
        require(
            isLenderApprovedByUser(client, msg.sender),
            LenderNotApproved()
        );
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

    function getMeanCreditScore(
        address client
    ) external view returns (uint256) {
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
        require(
            isLenderApprovedByUser(client, msg.sender),
            LenderNotApproved()
        );
        uint16 numberOfPaymentPlans = userProfiles[client].numberOfPaymentPlans;
        uint256[] memory paymentPlanIds = userProfiles[client].paymentPlanID;
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

    /// @dev Returns the payment plan ID of a user
    /// @param Id The ID of the payment plan to get
    function getNextInstalmentAmount(uint256 Id) public view returns (uint256) {
        uint32 totalPayments = paymentPlanID[Id].NumberOfInstalment;
        return paymentPlanID[Id].unpaidDebt / totalPayments;
    }

    function getNextInstalmentDeadline(
        uint256 Id
    ) public view returns (uint256) {
        return paymentPlanID[Id].lastPayment + getTimeBetweenInstalment(Id);
    }

    /// @dev Returns
    function getTimeBetweenInstalment(
        uint256 Id
    ) public view returns (uint256) {
        uint32 totalPayments = paymentPlanID[Id].NumberOfInstalment; // 5

        return (paymentPlanID[Id].time - block.timestamp) / totalPayments;
    }

    // ======== Booleans Functions =========

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

    function isInstalmentOnTime(uint256 Id) public view returns (bool) {
        return block.timestamp <= getNextInstalmentDeadline(Id);
    }

    function isInstalmentSufficient(
        uint256 Id,
        uint256 amount
    ) public view returns (bool) {
        return amount >= getNextInstalmentAmount(Id);
    }

    function getPaymentPlan(
        uint256 Id
    )
        public
        view
        returns (bool, uint256, uint256, uint256, uint256, uint32, uint16)
    {
        require(
            msg.sender == paymentPlanID[Id].owner ||
                hasRole(LENDER_ROLE, msg.sender),
            NotAuthorized()
        );
        PaymentPlan memory plan = paymentPlanID[Id];
        return (
            plan.active,
            plan.time,
            plan.paidDebt,
            plan.unpaidDebt,
            plan.totalPaid,
            plan.NumberOfInstalment,
            plan.interest
        );
    }

    // ================= Internal Functions ====================

    /// @dev Updates the credit score of a user based on the payment amount and plan Id
    /// @param amount The amount of the payment
    /// @param Id The ID of the payment plan
    /// @notice This function is called internally when a payment is made
    function updateCreditScore(uint256 amount, uint256 Id) internal {
        address client = paymentPlanID[Id].owner;
        address lender = msg.sender;
        uint16 currentScore = userProfiles[client].creditScore[lender];

        // Check payment conditions using getter functions
        bool meetsPaymentAmount = isInstalmentSufficient(Id, amount);
        bool isOnTime = isInstalmentOnTime(Id);
        uint256 expectedPaymentAmount = getNextInstalmentAmount(Id);

        if (isOnTime && meetsPaymentAmount) {
            // Maximum increase for perfect payment
            uint16 increase = 30;

            // Adjust increase based on payment size relative to expected
            if (amount > expectedPaymentAmount) {
                uint256 extraPaymentPercent = ((amount -
                    expectedPaymentAmount) * 100) / expectedPaymentAmount;
                // Additional points for paying more than expected (max +10)
                increase += uint16((extraPaymentPercent * 10) / 100);
            }

            // Cap increase at 40 points total
            increase = increase > 40 ? 40 : increase;

            // Apply increase while respecting max score of 850
            if (currentScore + increase <= 850) {
                userProfiles[client].creditScore[lender] =
                    currentScore +
                    increase;
            } else {
                userProfiles[client].creditScore[lender] = 850;
            }
        } else {
            // Base decrease for late payment
            uint16 decrease = 50;

            // Additional penalty if payment is also below expected amount
            if (!meetsPaymentAmount) {
                uint256 shortagePercent = ((expectedPaymentAmount - amount) *
                    100) / expectedPaymentAmount;
                // Additional penalty points (max +20)
                decrease += uint16((shortagePercent * 20) / 100);
            }

            // Cap decrease at 70 points total
            decrease = decrease > 70 ? 70 : decrease;

            // Apply decrease while respecting min score of 300
            if (currentScore > decrease + 300) {
                userProfiles[client].creditScore[lender] =
                    currentScore -
                    decrease;
            } else {
                userProfiles[client].creditScore[lender] = 300;
            }
        }
        paymentPlanID[Id].NumberOfInstalment--;
        emit CreditScoreUpdated(client);
    }

    function profileExists(address client) internal view returns (bool exists) {
        exists = userProfiles[client].exists;
    }
}
