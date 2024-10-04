// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

/// @title A library for handling events and errors in the Lottery contract
library LotteryLibrary {
    // Custom errors
    error LotteryClosed();
    error IncorrectTicketPrice();
    error OnlyOwner();
    error NoParticipants();
    error PrizeTransferFailed();
    error WithdrawalFailed();
    error NoFundsToWithdraw();

    // Events
    event TicketPurchased(address indexed participant);
    event WinnerSelected(address indexed winner, uint256 prize);
   
}