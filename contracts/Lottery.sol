// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./Library.sol"; // Import the library

/// @title A simple lottery contract
/// @author Your Name
/// @notice This contract allows users to buy tickets and randomly selects a winner
/// @dev This uses a pseudo-random number generation which is not secure for production use
contract Lottery {
    address public owner;
    uint256 public ticketPrice;
    address[] public participants;
    bool public lotteryOpen;

    // Use events from the library
    using LotteryLibrary for *;

    /// @notice Initializes the lottery with a ticket price
    /// @dev Can be called to reset the lottery parameters
    function initializeLottery(uint256 _ticketPrice) public {
        if (owner != address(0)) {
            revert LotteryLibrary.OnlyOwner(); // Use custom error if already initialized
        }
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        lotteryOpen = true;
    }

    /// @notice Allows a user to buy a lottery ticket
    /// @dev Adds the buyer's address to the participants array
    function buyTicket() public payable {
        if (!lotteryOpen) revert LotteryLibrary.LotteryClosed();
        if (msg.value != ticketPrice) revert LotteryLibrary.IncorrectTicketPrice();

        participants.push(msg.sender);
        emit LotteryLibrary.TicketPurchased(msg.sender); // Emit event from library
    }

    /// @notice Selects a winner for the lottery
    /// @dev Only the owner can call this function. Uses a pseudo-random selection process.
    function selectWinner() public {
        if (msg.sender != owner) revert LotteryLibrary.OnlyOwner();
        if (participants.length == 0) revert LotteryLibrary.NoParticipants();

        lotteryOpen = false;
        uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % participants.length;
        address winner = participants[index];
        uint256 prize = address(this).balance;

        (bool success, ) = winner.call{value: prize}("");
        if (!success) revert LotteryLibrary.PrizeTransferFailed();

        emit LotteryLibrary.WinnerSelected(winner, prize); // Emit event from library
        
        // Reset for next round
        delete participants;
        lotteryOpen = true;
    }

    /// @notice Returns the number of participants in the current lottery
    /// @return The number of participants
    function getParticipantCount() public view returns (uint256) {
        return participants.length;
    }

    /// @notice Allows the owner to withdraw funds from the contract
    function withdraw() public {
        if (msg.sender != owner) revert LotteryLibrary.OnlyOwner();
        uint256 balance = address(this).balance;
        if (balance == 0) revert LotteryLibrary.NoFundsToWithdraw();
        
        (bool success, ) = owner.call{value: balance}("");
        if (!success) revert LotteryLibrary.WithdrawalFailed();
    }
}