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
    bytes32 public constant LENDER_ROLE = keccak256("LENDER_ROLE");

    struct PaymentPlan {
        address Lender;
        address owner;
        bool active;
        uint256 time;
        uint256 lastPayment;
        uint256 paidDebt;
        uint256 unpaidDebt;
        uint256 totalPaid;
        uint32 NumberOfInstalment;
        uint16 interest;
        bool defaulted;
    }

    struct UserProfile {
        bool exists;
        address[] lenders;
        // uint16 meanScore;
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
    error OnTime();
    error NotActive();
    error NotDefaulted();
    error AlreadyExists();
    error NotAuthorized();
    error LenderIsNotClient();
    error LenderNotApproved();
    error ProfileDoesNotExist();
    error ProfileAlreadyExists();
    error CreditScoreAlreadyExists();
    error PaymentPlanDoNotMatchUser();
    error ProfileDoesNotHaveCreditScore();
    error NotDefaultedOrCannotBeCalledTwice();

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
    /// @param id The ID of the payment plan to approve
    /// @notice This function can only be called by the owner that intends to accept
    /// the payment plan, and the payment plan must be active, and the user must have
    /// a credit score from the lender that created the payment plan
    function approveNewPaymentPlan(uint256 id) external whenNotPaused {
        require(
            paymentPlanID[id].owner == msg.sender,
            PaymentPlanDoNotMatchUser()
        );
        require(paymentPlanID[id].active == false, NotActive());
        uint256[] memory planID = userProfiles[msg.sender].paymentPlanID;
        for (uint256 i = 0; i < planID.length; i++) {
            if (planID[i] == id) revert AlreadyExists();
        }
        //// This startes the Payment plan Clock
        paymentPlanID[id].time = paymentPlanID[id].time + block.timestamp;
        paymentPlanID[id].lastPayment = block.timestamp;
        paymentPlanID[id].active = true;
        userProfiles[msg.sender].numberOfPaymentPlans++;
        userProfiles[msg.sender].paymentPlanID.push(id);
    }

    /// @dev Only the user can call this function make sure ta pass in the user as signer when
    /// calling this function in the frontend
    /// @notice returns the profile stats of the user
    /// @return bool if the user has a profile
    /// @return array of lenders that have given the user a credit score
    /// @return array of paymentPlanID
    /// @return number of credit scores
    /// @return number of payment plans
    function getMyProfile()
        public
        view
        returns (bool, address[] memory, uint256[] memory, uint16, uint16)
    {
        return (
            userProfiles[msg.sender].exists,
            userProfiles[msg.sender].lenders,
            userProfiles[msg.sender].paymentPlanID,
            userProfiles[msg.sender].numberOfCreditScores,
            userProfiles[msg.sender].numberOfPaymentPlans
        );
    }

    /// @dev Returns all the payment plans of a user
    /// @notice This function can only be called by the owner of the payment plan
    /// @return array of active payment plans
    /// @return array of time the payment plan was created
    /// @return array of paid debt
    /// @return array of unpaid debt
    /// @return array of total paid
    /// @return array of number of instalments
    /// @return array of interest rate
    function getAllMyPaymentPlans()
        public
        view
        returns (
            bool[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint32[] memory,
            uint16[] memory
        )
    {
        uint256[] memory planID = userProfiles[msg.sender].paymentPlanID;
        bool[] memory active = new bool[](planID.length);
        uint256[] memory time = new uint256[](planID.length);
        uint256[] memory paidDebt = new uint256[](planID.length);
        uint256[] memory unpaidDebt = new uint256[](planID.length);
        uint256[] memory totalPaid = new uint256[](planID.length);
        uint32[] memory NumberOfInstalment = new uint32[](planID.length);
        uint16[] memory interest = new uint16[](planID.length);
        for (uint i = 0; i < planID.length; i++) {
            uint256 Id = planID[i];
            require(
                msg.sender == paymentPlanID[Id].owner ||
                    hasRole(LENDER_ROLE, msg.sender),
                NotAuthorized()
            );
            PaymentPlan memory plan = paymentPlanID[Id];
            active[i] = plan.active;
            time[i] = plan.time;
            paidDebt[i] = plan.paidDebt;
            unpaidDebt[i] = plan.unpaidDebt;
            totalPaid[i] = plan.totalPaid;
            NumberOfInstalment[i] = plan.NumberOfInstalment;
            interest[i] = plan.interest;
        }
        return (
            active,
            time,
            paidDebt,
            unpaidDebt,
            totalPaid,
            NumberOfInstalment,
            interest
        );
    }

    //==================== Lender Functions ====================

    /** 
      @dev CreditScore ranges between 300 and 850
      @notice This function can only be called by a lender that has been approved by the user
      @notice This function can only be called once per user
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

    //BUG:if a user does not pay the scores wont be updated

    /// @notice There is a design choice here to not limit the lenders ability to make payment
    /// more often than the payment plan was meant to. This could increase the credit score of the user unfairly
    /// for that lender and increase the MeanCreditScore of the user.
    /// It is up to the lender to decide how to let thier users pay off the debt.
    /// @dev This function is for the lender to use in their own system
    /// @param amount The amount of the payment
    /// @param id The ID of the payment plan
    function payment(
        uint256 amount,
        uint256 id
    ) external onlyRole(LENDER_ROLE) nonReentrant {
        // checks if the taker has payed within the paymentplan give + score else - score
        // if the whole debt is paid, the payment plan is set to inactive
        require(paymentPlanID[id].active == true, NotActive());
        if (amount >= paymentPlanID[id].unpaidDebt) {
            paymentPlanID[id].unpaidDebt = 0;
            paymentPlanID[id].active = false;
            paymentPlanID[id].paidDebt += amount;
            paymentPlanID[id].totalPaid += amount;
            userProfiles[paymentPlanID[id].owner].creditScore[msg.sender] += 15;
            emit PaymentPlanPaid(msg.sender);
            return;
        } else {
            paymentPlanID[id].unpaidDebt -= amount;
            paymentPlanID[id].paidDebt += amount;
            paymentPlanID[id].totalPaid += amount;
        }
        updateCreditScore(amount, id);
        paymentPlanID[id].defaulted = false;
        emit PaymentPlanPaid(msg.sender);
    }

    /// @dev This function is for the lender to use in their own system
    /// @notice this function is meant to be called by the lender if the user does not pay
    /// @param id The ID of the payment plan
    function updateScoresIfDefault(uint256 id) external onlyRole(LENDER_ROLE) {
        require(paymentPlanID[id].active == true, NotActive());
        require(isInstalmentOnTime(id) == false, OnTime());
        require(
            isPaymentPlanDefaulted(id) == false,
            NotDefaultedOrCannotBeCalledTwice()
        );
        address user = paymentPlanID[id].owner;
        if (userProfiles[user].creditScore[msg.sender] - 50 < 300) {
            userProfiles[user].creditScore[msg.sender] = 290;
        } else {
            userProfiles[user].creditScore[msg.sender] -= 50;
        }
        paymentPlanID[id].defaulted = true;
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
            Lender: msg.sender,
            owner: client,
            active: false,
            time: time,
            lastPayment: 0,
            paidDebt: 0,
            unpaidDebt: amount,
            totalPaid: 0,
            NumberOfInstalment: NumberOfPayments,
            interest: uint16(interest),
            defaulted: false
        });

        emit PaymentPlanCreated(ID);
        return ID;
    }

    /// @dev Returns the credit score of a user
    /// @notice This function can only be called by a lender that has been approved by the user
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

    /// @dev Adds a lender to the list of active lenders
    /// @notice This function can only be called by an admin
    /// @param lender The address of the lender to add
    function addLender(address lender) external onlyRole(ADMIN_ROLE) {
        _grantRole(LENDER_ROLE, lender);
        activeLenders.push(lender);
        emit LenderAdded(lender);
    }

    /** @dev If there is to many lenders this function no longer works because of hitting
     * the Gas limit of a single transaction.
     * if that is the case, we need to upgrade this contract and remove the foor loop.
     */
    /// @dev Removes a lender from the list of active activeLenders
    /// @notice This function can only be called by an admin
    /// @param lender The address of the lender to remove
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
    /// @dev Updates the address of a lender
    /// @notice This function can only be called by an admin
    /// @param oldLender The address of the lender to update
    /// @param newLender The new address of the lender
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

    /// @dev Returns the list of active lenders
    /// @notice This function can only be called by an admin
    /// @return lenders array of active lenders
    function getActiveLenders()
        public
        view
        onlyRole(ADMIN_ROLE)
        returns (address[] memory lenders)
    {
        lenders = activeLenders;
    }

    // ================= Getter Functions ======================

    /// @dev Returns the mean credit score of a user
    /// @notice This function can only be called by a lender that has been approved by the user or the user themselves
    /// @param client The address of the user to get the mean credit score for
    /// @return The mean credit score of the user
    function getMeanCreditScore(
        address client
    ) external view returns (uint256) {
        require(
            hasRole(LENDER_ROLE, msg.sender) || msg.sender == client,
            NotAuthorized()
        );
        if (hasRole(LENDER_ROLE, msg.sender)) {
            require(
                isLenderApprovedByUser(client, msg.sender),
                LenderNotApproved()
            );
        }
        address[] memory lenders = userProfiles[client].lenders;
        require(lenders.length > 0, ProfileDoesNotHaveCreditScore());

        uint256 totalScore;
        for (uint256 i = 0; i < lenders.length; i++) {
            totalScore += userProfiles[client].creditScore[lenders[i]];
        }
        return totalScore / lenders.length;
    }

    /// @dev Returns the total unpaid debt of a user
    /// @notice This function can only be called by a lender that has been approved by the user or the user themselves
    /// @param client The address of the user to get the total unpaid debt for
    /// @return The total unpaid debt of the user
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

    /// @dev Returns the number of credit scores of a user
    /// @param client The address of the user to get the number of credit scores for
    /// @return numberOfPaymentPlans The number of credit scores of the user
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
    /// @param id The ID of the payment plan to get
    /// @return The payment plan ID of the user
    function getNextInstalmentAmount(uint256 id) public view returns (uint256) {
        uint32 totalPayments = paymentPlanID[id].NumberOfInstalment;
        return paymentPlanID[id].unpaidDebt / totalPayments;
    }

    /// @dev Returns the next instalment deadline of a user
    /// @param id The ID of the payment plan to get
    /// @return The next instalment deadline of the user
    function getNextInstalmentDeadline(
        uint256 id
    ) public view returns (uint256) {
        return paymentPlanID[id].lastPayment + getTimeBetweenInstalment(id);
    }

    /// @dev Returns the time between instalments of a user for a payment plan
    /// @param id The ID of the payment plan to get
    /// @return The time between instalments of the user
    function getTimeBetweenInstalment(
        uint256 id
    ) public view returns (uint256) {
        uint32 totalPayments = paymentPlanID[id].NumberOfInstalment; // 5

        return (paymentPlanID[id].time - block.timestamp) / totalPayments;
    }

    // ======== Booleans Functions =========

    /// @param client The address of the user to check
    /// @return a boolean if the user has a profile
    function isClientActive(address client) public view returns (bool) {
        require(hasRole(LENDER_ROLE, msg.sender), LenderIsNotClient());
        address lender = msg.sender;
        bool active = (userProfiles[client].creditScore[lender] > 0);
        return active;
    }

    /// @param client The address of the user to check
    /// @param lender The address of the lender to check
    /// @return approved a boolean if the lender is approved by the user
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

    /// @dev Returns whether a user has a profile
    /// @param lender: The address of the user to check
    /// @return isClient if the Lender is a client of the CreditScore protocol
    function isLenderClient(
        address lender
    ) public view returns (bool isClient) {
        isClient = hasRole(LENDER_ROLE, lender);
    }

    /// @param id the payment plan ID
    /// @return onTime boolean if the payment plan is on time
    function isInstalmentOnTime(uint256 id) public view returns (bool onTime) {
        onTime = block.timestamp <= getNextInstalmentDeadline(id);
    }

    /// @param id the payment plan ID
    /// @param amount the amount of the payment
    /// @return sufficient boolean if the payment is sufficient
    function isInstalmentSufficient(
        uint256 id,
        uint256 amount
    ) public view returns (bool sufficient) {
        sufficient = amount >= getNextInstalmentAmount(id);
    }

    /// @param id the payment plan is of the user
    /// @return defaulted boolean if the payment plan is defaulted
    function isPaymentPlanDefaulted(
        uint256 id
    ) public view returns (bool defaulted) {
        defaulted = paymentPlanID[id].defaulted;
    }

    /// @param id the payment plan ID
    /// @return lender of the payment plan
    function getLenderFromId(uint256 id) public view returns (address lender) {
        lender = paymentPlanID[id].Lender;
    }

    /// @notice This function can only be called by the owner of the payment plan or a lender
    /// @param id the payment plan ID
    /// @return active of the payment plan
    /// @return time of the payment plan
    /// @return paidDebt of the payment plan
    /// @return unpaidDebt of the payment plan
    /// @return totalPaid of the payment plan
    /// @return NumberOfInstalment of the payment plan
    /// @return interest of the payment plan
    function getPaymentPlan(
        uint256 id
    )
        public
        view
        returns (bool, uint256, uint256, uint256, uint256, uint32, uint16)
    {
        require(
            msg.sender == paymentPlanID[id].owner ||
                hasRole(LENDER_ROLE, msg.sender),
            NotAuthorized()
        );
        PaymentPlan memory plan = paymentPlanID[id];
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
    /// @param id The ID of the payment plan
    /// @notice This function is called internally when a payment is made
    function updateCreditScore(uint256 amount, uint256 id) internal {
        address client = paymentPlanID[id].owner;
        address lender = msg.sender;
        uint16 currentScore = userProfiles[client].creditScore[lender];

        // Check payment conditions using getter functions
        bool meetsPaymentAmount = isInstalmentSufficient(id, amount);
        bool isOnTime = isInstalmentOnTime(id);
        uint256 expectedPaymentAmount = getNextInstalmentAmount(id);

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
        paymentPlanID[id].NumberOfInstalment--;
        emit CreditScoreUpdated(client);
    }

    function profileExists(address client) internal view returns (bool exists) {
        exists = userProfiles[client].exists;
    }
}
