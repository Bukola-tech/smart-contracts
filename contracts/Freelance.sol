// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelancePayment {
    address payable public freelancerAddress;
    uint public contractDeadline;
    address public clientAddress;
    uint public totalContractValue;
    bool private reentrancyLock = false;

    struct PaymentRequest {
        string description;
        uint amount;
        bool isLocked;
        bool isPaid;
    }

    PaymentRequest[] public paymentRequests;

    event RequestUnlocked(uint256 indexed requestId, bool isLocked);
    event RequestCreated(uint256 indexed requestId, string description, uint256 amount);
    event RequestPaid(address indexed freelancer, uint256 amount);
    event ExcessFundsWithdrawn(address indexed freelancer, uint256 amount);

    modifier onlyFreelancer() {
        require(msg.sender == freelancerAddress, "ONLY FREELANCER");
        _;
    }

    modifier onlyClient() {
        require(msg.sender == clientAddress, "ONLY CLIENT");
        _;
    }

    modifier preventReentrancy() {
        require(!reentrancyLock, "Reentrant call detected");
        _;
    }

    /**
     * @dev Initializes the contract with freelancer, deadline, and receives initial funds from the client.
     * @param _freelancerAddress The address of the freelancer to be paid.
     * @param _contractDeadline The deadline for the contract.
     */
    constructor(address payable _freelancerAddress, uint _contractDeadline) payable {
        freelancerAddress = _freelancerAddress;
        contractDeadline = _contractDeadline;
        clientAddress = msg.sender;
        totalContractValue = msg.value;
    }

    receive() external payable {
        totalContractValue += msg.value;  // Accumulate additional payments
    }

    /**
     * @dev Creates a new payment request by the freelancer.
     * @param _description The description of the work/deliverable.
     * @param _amount The payment amount requested.
     */
    function createPaymentRequest(string memory _description, uint _amount) external onlyFreelancer {
        PaymentRequest memory newRequest = PaymentRequest({
            description: _description,
            amount: _amount,
            isLocked: true,
            isPaid: false
        });

        paymentRequests.push(newRequest);
        emit RequestCreated(paymentRequests.length - 1, _description, _amount);  // Emit event with request ID
    }

    /**
     * @dev Allows the client to unlock a request for payment.
     * @param _index The index of the request to unlock.
     */
    function unlockPaymentRequest(uint256 _index) external onlyClient {
        PaymentRequest storage request = paymentRequests[_index];
        require(request.isLocked, "Already unlocked");
        request.isLocked = false;
        emit RequestUnlocked(_index, false);
    }

    /**
     * @dev Freelancer claims payment for an unlocked request.
     * @param _index The index of the request to be paid.
     */
    function claimPayment(uint256 _index) external onlyFreelancer preventReentrancy {
        PaymentRequest storage request = paymentRequests[_index];
        require(!request.isLocked, "Request is locked");
        require(!request.isPaid, "Already paid");

        reentrancyLock = true;
        request.isPaid = true;

        (bool sent, ) = freelancerAddress.call{value: request.amount}("");
        require(sent, "Transfer failed");

        reentrancyLock = false;
        emit RequestPaid(freelancerAddress, request.amount);
    }

    /**
     * @dev Allows the freelancer to withdraw any excess funds in the contract.
     */
    function withdrawExcessFunds() external onlyFreelancer {
        uint excess = address(this).balance;
        require(excess > 0, "No excess funds");

        (bool success, ) = freelancerAddress.call{value: excess}("");
        require(success, "Withdrawal failed");

        emit ExcessFundsWithdrawn(freelancerAddress, excess);
    }

    /**
     * @dev Returns all payment requests. Only the client can view this.
     */
    function getAllPaymentRequests() external view onlyClient returns (PaymentRequest[] memory) {
        return paymentRequests;
    }
}
