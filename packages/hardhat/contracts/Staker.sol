// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;

    //set deadline
    uint256 public deadline = block.timestamp + 72 hours;

    bool public openForWithdraw;

    error NoSeAgotadoTiempo();

    event Stake(address sender, uint256 value);

    modifier deadlinePassed(bool requireDeadlinePassed) {
        uint256 timeRemaining = timeLeft();
        if (requireDeadlinePassed) {
            require(timeRemaining <= 0, "Deadline has not been passed yet");
        } else {
            require(timeRemaining > 0, "Deadline is already passed");
        }
        _;
    }

    /// Modifier that checks whether the external contract is completed
    modifier stakingNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Staking period has completed");
        _;
    }

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() public payable deadlinePassed(false) stakingNotCompleted {
        require(msg.value > 0, "Invalid amount");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    function execute() public stakingNotCompleted {
        // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
        if (block.timestamp < deadline) {
            revert NoSeAgotadoTiempo();
        }
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public payable deadlinePassed(true) stakingNotCompleted {
        if (openForWithdraw) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            revert();
        }
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
