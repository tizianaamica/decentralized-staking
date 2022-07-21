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

    event Received(address sender, uint256 value);

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Received(msg.sender, msg.value);
    }

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() public payable {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function

    /*function execute() public {
        // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
        if (block.timestamp >= deadline) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }*/

     function execute() public {
        // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
        if (block.timestamp < deadline){
            revert NoSeAgotadoTiempo();
        }
        if (address(this).balance>=threshold){
            exampleExternalContract.complete{value: address(this).balance}() ;
        }else {
            openForWithdraw=true;
        }
    }

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public payable {
        if (openForWithdraw) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            revert();
        }
        /*require(openForWithdraw, "Not open for withdraw");
        //tranferir el dinero al usuario que llama la funcion
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "userBalance is 0");
        //colocar el balance a 0
        balances[msg.sender] = 0;
        (bool sent, ) = _to.call{value: userBalance}("");
        require(sent, "Failed to send to address");*/
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

}
