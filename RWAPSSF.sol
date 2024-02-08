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
    uint public timeLimit = 15 seconds ;
    mapping (uint => Player) public player;
    mapping  (address => uint) public  addressToPlayer ;
    CommitReveal public  commitReveal;

    constructor() {
        commitReveal = new CommitReveal();
    }

    function addPlayer() public payable {
        require(numPlayer < 2, "require only 2 player");
        require(player[0].addr != msg.sender, "you have been registered");
        require(msg.value == 1 ether, "please fill 1 ether");

        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        player[numPlayer].timestamp = block.timestamp;
        addressToPlayer[msg.sender] = numPlayer;
        numPlayer++;
    }

    function input(uint choice) public  {

        uint idx = addressToPlayer[msg.sender]; // แก้: 2.ยากต่อการจะรู้ account ใดเป็น 1, 2
        require(numPlayer == 2, "we need two player first");
        require(msg.sender == player[idx].addr);
        require(choice >= 0 || choice < 7, "choice should be 0-7 only");
        player[idx].choice = choice;
        player[numPlayer].timestamp = block.timestamp;

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


    // แก้: 3, 4
    function withdraw() public {
        require(numPlayer == 1 || numPlayer == 2, "have no player to withdraw");
        uint idx ;
        
        if (numPlayer == 1) { // แก้: 3. เงินของ plyer 0 อาจถูกล็อกหากไม่มี player 1 มาลงขัน
            idx = 0;
        
        } else { // แก้: 4. กรณี ได้ 2 player แต่มีแค่ player เดียวที่ลงขัน ทำให้เงินถูกล้อก 
            // หาว่า player คนไหนเป็นผู้ถูกล็อก
            uint choice0 = player[0].choice;
            uint choice1 = player[1].choice;

            // หากยังไม่เลือกทั้งคู่ให้ผ่านไปเลย
            require(!(choice0 == 7 && choice1 == 7), "you need to call input first") ;

            // player 0 ถูก ล็อก
            if (choice0 != 7) {
                idx = 0;
            } else {
                idx = 1;
            }
        }
        // ถอนเงินจาก reward ไปยัง player
        require(msg.sender == player[idx].addr, "unauthorize to withdraw");
        require(block.timestamp -  player[idx].timestamp > timeLimit, "please wait to withdraw within 1 minute");
        address payable account = payable(player[idx].addr);
        account.transfer(reward);

        _restartGame();
    }


    // แก้: 5.ทำให้ contract นี้เล่นได้หลายรอบ
    function _restartGame() private  {
        numPlayer = 0;
        reward = 0;
        numInput = 0;

        // delete player ;
        address account0 = player[0].addr;
        address account1 = player[1].addr;

        delete addressToPlayer[account0] ;
        delete addressToPlayer[account1] ;

        delete player[0];
        delete player[1];        
        
    }
}