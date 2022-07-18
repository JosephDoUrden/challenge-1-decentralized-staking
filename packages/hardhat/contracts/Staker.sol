// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;

  event Stake(address indexed sender, uint256 amount);


  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted(){
    bool completed = exampleExternalContract.completed();
    require(!completed, "Staking process already completed");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notCompleted{
    require(block.timestamp<=deadline, "You can not stake after the stake time");
    require(msg.value>=0, "You need to stake above 0 Ether");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public notCompleted{
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public notCompleted returns(bool) {
    require(openForWithdraw, 'Withdraw not allowed.');
    (bool sent, ) = msg.sender.call{value: balances[msg.sender]}('');
    return sent;
  }

  // Add a `withdraw()` function to let users withdraw their balance


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256) {
    if (deadline > block.timestamp) {
      return deadline - block.timestamp;
    }
    else{
      return 0;
    }
  }


  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable{
    stake();
  }
}
