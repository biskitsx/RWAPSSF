// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "contracts/CommitReveal.sol";


contract RPS is CommitReveal{
    struct Player {
        uint choice; // 0 - Rock, 1 - Water, 2 - Air, 3 - Paper, 4 - Sponge, 5 - Scissors, 6 - Fire, 7 - Undefined
        address addr;
        uint timestamp;
        bool isCommited;
    }

    // variable
    uint public numPlayer = 0;
    uint public reward = 0;
    uint public numInput = 0;
    uint public timeLimit = 5 minutes ;
    uint public revealCount = 0;

    // mapping
    mapping (uint => Player) public player;
    mapping  (address => uint) public  addressToPlayer ; // แก้: 2.ยากต่อการจะรู้ account ใดเป็น 1, 2

    function addPlayer() public payable {
        require(numPlayer < 2, "RPS::addPlayer: Require only 2 player");
        require(player[0].addr != msg.sender, "RPS::addPlayer: You already registered");
        require(msg.value == 1 ether, "RPS::addPlayer: Please fill 1 ether");

        reward += msg.value;
        // init player
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        player[numPlayer].timestamp = block.timestamp;
        player[numPlayer].isCommited = false;
        addressToPlayer[msg.sender] = numPlayer;
        numPlayer++;
    }


    function input(uint choice, string memory salt) public  {
        uint idx = addressToPlayer[msg.sender]; 
        require(numPlayer == 2, "RPS::input: We need two player first");
        require(numInput < 2, "RPS::input: Can not add more input");
        require(msg.sender == player[idx].addr);
        require(choice >= 0 || choice < 7, "RPS::input: choice should be 0-7 only");
        require(player[idx].isCommited == false, "RPS::input: You already committed");
        player[idx].timestamp = block.timestamp;
        player[idx].isCommited = true;

        // hash choice + salt จากนั้น commit
        bytes32 bSalt = bytes32(abi.encodePacked(salt));
        bytes32 bChoice = bytes32(abi.encodePacked(choice));
        bytes32 hashData = getSaltedHash(bChoice, bSalt) ;
        commit(hashData);
        numInput++;
    }

    function revealChoice(uint choice, string memory salt) public  {
        require(numInput == 2, "RPS::revealChoice: Input should equal 2");
        
        uint idx = addressToPlayer[msg.sender];
        bytes32 bSalt = bytes32(abi.encodePacked(salt));
        bytes32 bChoice = bytes32(abi.encodePacked(choice));
        revealAnswer(bChoice, bSalt);
        player[idx].choice = choice;
        revealCount++;
        if (revealCount == 2) {
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
        require(numPlayer == 1 || numPlayer == 2, "RPS::withdraw: Have no player to withdraw");
        require(msg.sender == player[0].addr || msg.sender == player[1].addr, "RPS::withdraw: Unauthorize to withdraw");
        uint idx = addressToPlayer[msg.sender];

        // state 1: มีคนลงขันแค่คนเดียว
        if (numPlayer == 1) {
            idx = 0;
        }
        // state 2: ลงขันสองคน แต่มีคนไม่ยอม commit
        else if (numPlayer == 2 && numInput < 2) {
            require(player[idx].isCommited == true, "RPS::withdraw: You need to commit");
        } 
        // state 3: ลงขันสองคน ยอม commit แต่มีคนไม่ยอม reveal
        else if (numPlayer == 2 && numInput == 2 && revealCount < 2) {
            require(commits[msg.sender].revealed == true, "RPS::withdraw: You need to Reveal");

        }
        // ถอนเงินจาก reward ไปยัง player
        require(msg.sender == player[idx].addr, "RPS::withdraw: Unauthorize to withdraw");
        require(block.timestamp -  player[idx].timestamp > timeLimit, "RPS::withdraw: Please wait to withdraw within 1 hours");
        address payable account = payable(player[idx].addr);
        account.transfer(reward);

        _restartGame();
    }


    // แก้: 5.ทำให้ contract นี้เล่นได้หลายรอบ
    function _restartGame() private  {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        revealCount = 0;

        // delete player ;
        address account0 = player[0].addr;
        address account1 = player[1].addr;

        delete addressToPlayer[account0] ;
        delete addressToPlayer[account1] ;

        delete player[0];
        delete player[1];        
    }
}