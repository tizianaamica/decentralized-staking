// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;

    //set deadline
    uint256 public deadline = block.timestamp + 30 seconds;

    bool public openForWithdraw;

    event Stake(address sender, uint256 value);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Staking period has completed");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() public payable notCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function

    function execute() public notCompleted {
        // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
        require(block.timestamp >= deadline, "No se ha cumplido el deadline");

        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            // If the `threshold` was not met, allow everyone to call a `withdraw()` function
            openForWithdraw = true;
        }
    }

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw(address payable _to) public notCompleted {
        require(openForWithdraw, "Not open for withdraw");
        //tranferir el dinero al usuario que llama la funcion
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "userBalance is 0");
        //colocar el balance a 0
        balances[msg.sender] = 0;
        (bool sent, ) = _to.call{value: userBalance}("");
        require(sent, "Failed to send to address");
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
