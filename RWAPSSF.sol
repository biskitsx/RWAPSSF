// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "contracts/CommitReveal.sol";


contract RPS{
    struct Player {
        uint choice; // 0 - Rock, 1 - Water, 2 - Air, 3 - Paper, 4 - Sponge, 5 - Scissors, 6 - Fire, 7 - Undefined
        address addr;
        uint timestamp;
    }

    uint public numPlayer = 0;
    uint public reward = 0;
    uint public numInput = 0;
    mapping (uint => Player) public player;
    mapping  (address => uint) public  addressToPlayer ;
    CommitReveal public  commitReveal;

    constructor() {
        commitReveal = new CommitReveal();
    }

    function addPlayer() public payable {
        require(numPlayer < 2, "require only 2 player");
        require(msg.value == 1 ether, "please fill 1 ether");

        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        addressToPlayer[msg.sender] = numPlayer;
        numPlayer++;
    }

    function input(uint choice) public  {

        uint idx = addressToPlayer[msg.sender]; // แก้: 2.ยากต่อการจะรู้ account ใดเป็น 1, 2
        require(numPlayer == 2, "we need two player first");
        require(msg.sender == player[idx].addr);
        require(choice >= 0 || choice < 7, "choice should be 0-7 only");
        player[idx].choice = choice;

        // hash choice จากนั้น commit
        // bytes32 hashData = commitReveal.getHash(bytes32(choice));
        // commitReveal.commit(hashData);
        numInput++;
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }



    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if ((p0Choice + 1) % 7 == p1Choice || (p0Choice + 2) % 7 == p1Choice || (p0Choice + 3) % 7 == p1Choice) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 7 == p0Choice || (p1Choice + 2) % 7 == p0Choice  || (p1Choice + 3) % 7 == p0Choice ) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        _restartGame();
    }

    // แก้: 5.ทำให้ contract นี้เล่นได้หลายรอบ
    function _restartGame() private  {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        // delete player ;
        // delete addressToPlayer ;
    }
}