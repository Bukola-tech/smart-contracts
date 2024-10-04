// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Bank {
    struct Account {
        string name;
        uint balance;
    }

    mapping(address => Account) private customers; // Made customers private for better encapsulation
    uint256 constant ETHTOWEI = 1 ether; // Use 1 ether for better readability

    // Events for logging
    event AccountCreated(address indexed accountHolder, string name);
    event DepositMade(address indexed accountHolder, uint amount);
    event WithdrawalMade(address indexed accountHolder, uint amount);
    event TransferMade(address indexed from, address indexed to, uint amount);

    // Custom error types
    error AccountAlreadyExists();
    error AccountDoesNotExist();
    error InsufficientBalance();
    error TransferFailed();

    // can accept deposits
    receive() external payable {}

    function doesAccountExist() public view returns (bool) {
        return bytes(customers[msg.sender].name).length > 0;
    }

    function doesAccountExistWithParams(address _address) internal view returns (bool) {
        return bytes(customers[_address].name).length > 0;
    }

    function createAccount(string memory _name) public {
        if (doesAccountExist()) revert AccountAlreadyExists();
        customers[msg.sender] = Account(_name, 0);
        emit AccountCreated(msg.sender, _name);
    }

    function getBalance() public view returns (uint) {
        if (!doesAccountExist()) revert AccountDoesNotExist();
        return customers[msg.sender].balance / ETHTOWEI;
    }

    function deposit() public payable {
        if (!doesAccountExist()) revert AccountDoesNotExist();
        require(msg.value > 0, "You cannot send zero!");
        customers[msg.sender].balance += msg.value;
        emit DepositMade(msg.sender, msg.value);
    }

    function withdrawInEth(bool _emptyAccount, uint _amountInEth) public {
        if (!doesAccountExist()) revert AccountDoesNotExist();

        if (_emptyAccount) {
            uint balance = customers[msg.sender].balance;
            customers[msg.sender].balance = 0; // Reset balance before transfer
            (bool success,) = msg.sender.call{value: balance}("");
            if (!success) revert TransferFailed();
            emit WithdrawalMade(msg.sender, balance);
        } else {
            uint amountInWei = _amountInEth * ETHTOWEI;
            if (customers[msg.sender].balance < amountInWei) revert InsufficientBalance();
            customers[msg.sender].balance -= amountInWei;
            (bool success,) = msg.sender.call{value: amountInWei}("");
            if (!success) revert TransferFailed();
            emit WithdrawalMade(msg.sender, amountInWei);
        }
    }

    function transfer(address _recipient, uint256 _amountInEth) public {
        if (!doesAccountExist()) revert AccountDoesNotExist();
        if (!doesAccountExistWithParams(_recipient)) revert AccountDoesNotExist();
        
        uint amountInWei = _amountInEth * ETHTOWEI;
        if (customers[msg.sender].balance < amountInWei) revert InsufficientBalance();
        
        customers[msg.sender].balance -= amountInWei;
        customers[_recipient].balance += amountInWei;
        
        (bool success,) = _recipient.call{value: amountInWei}("");
        if (!success) revert TransferFailed();
        
        emit TransferMade(msg.sender, _recipient, amountInWei);
    }
}