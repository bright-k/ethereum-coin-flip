// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract CoinFlip {
    uint constant MAX_CASE = 2;
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_BET = 10 ether;
    uint constant FLIP_FEE_PERCENT = 5;
    uint constant FLIP_MIN_FEE = 0.005 ether;

    address public owner;
    uint public lockedInBets;

    struct Bet {
        uint amount;
        uint8 numOfBetBit;
        uint placeBlockNumber;
        uint8 mask;
        address gambler;
    }

    mapping (address => Bet) bets;

    event Reveal(uint reveal);
    event Payment(address indexed beneficiary, uint amount);
    event FailedPayment(address indexed beneficiary, uint amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (owner == msg.sender, "Only owner can call this function.");
        _;
    }

    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount + lockedInBets <= address(this).balance, "lager then balance.");
        sendFunds(beneficiary, withdrawAmount);
    }

    function sendFunds(address beneficiary, uint amount) private {
        if (payable(beneficiary).send(amount)) {
            emit Payment(beneficiary, amount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

    function kill() external onlyOwner {
        require (0 == lockedInBets, "All bets should be processed before self-destruct.");
        selfdestruct(payable(owner));
    }

    fallback () external payable {}

    receive () external payable {}

    function placeBet(uint8 betMask) external payable {
        uint amount = msg.value;

        require(MIN_BET <= amount && amount <= MAX_BET, "Amount is out of age");
        require(0 < betMask && betMask < 256, "Mask should be 8 bit");

        Bet storage bet = bets[msg.sender];

        require(bet.gambler == address(0), "Bet should be empty state.");

        uint8 numOfBetBit = countBits(betMask);

        bet.amount = amount;
        bet.numOfBetBit = numOfBetBit;
        bet.placeBlockNumber = block.number;
        bet.mask = betMask;
        bet.gambler = msg.sender;

        uint possibleWinningAmount = getWinningAmount(amount, numOfBetBit);
        lockedInBets += possibleWinningAmount;

        require(lockedInBets < address(this).balance, "Cannot afford to pay the bet.");
    }

    function getWinningAmount(uint amount, uint8 numOfBetBit) private pure returns (uint winningAmount) {
        require(0 < numOfBetBit && numOfBetBit < MAX_CASE, "Probability is out of range.");

        uint flipFee = amount * FLIP_FEE_PERCENT / 100;
        if (flipFee < FLIP_MIN_FEE) {
            flipFee = FLIP_MIN_FEE;
        }

        uint reward = amount / (MAX_CASE + (numOfBetBit - 1));

        winningAmount = (amount - flipFee) + reward;
    }


    function revealResult(uint8 seed) external {
        Bet storage bet = bets[msg.sender];
        uint amount = bet.amount;
        uint8 numOfBetBit = bet.numOfBetBit;
        uint placeBlockNumber = bet.placeBlockNumber;
        address gambler = bet.gambler;

        require(0 < amount, "Bet should be in an 'active' state.");
        require(placeBlockNumber < block.number, "revealResult in the same block as placeBet, or before.");

        bytes32 random = keccak256(abi.encodePacked(blockhash(block.number-seed), blockhash(placeBlockNumber)));
        uint reveal = uint(random) % MAX_CASE;

        uint winningAmount = 0;
        uint possibleWinningAmount = 0;
        possibleWinningAmount = getWinningAmount(amount, numOfBetBit);

        if (0 != (2 ** reveal) & bet.mask) {
            winningAmount = possibleWinningAmount;
        }

        emit Reveal(2 ** reveal);

        if (0 < winningAmount) {
            sendFunds(gambler, winningAmount);
        }

        lockedInBets -= possibleWinningAmount;
        clearBet(msg.sender);
    }

    function clearBet(address player) private {
        Bet storage bet = bets[player];

        if (0 < bet.amount) return;

        bet.amount = 0;
        bet.numOfBetBit = 0;
        bet.placeBlockNumber = 0;
        bet.mask = 0;
        bet.gambler = address(0);
    }

    function refundBet() external {
        Bet storage bet = bets[msg.sender];
        require(bet.placeBlockNumber < block.number, "refundBet in the same block as placeBet, or before");

        uint amount = bet.amount;
        require(0 < amount, "Bet should be in an 'active' state.");

        uint8 numOfBetBit = bet.numOfBetBit;

        sendFunds(bet.gambler, amount);

        uint possibleWinningAmount = getWinningAmount(amount, numOfBetBit);
        lockedInBets -= possibleWinningAmount;

        clearBet(msg.sender);
    }

    function checkHouseFund() public view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function countBits(uint8 _num) internal pure returns(uint8) {
        uint8 count;
        while(0 < _num) {
            count += _num & 1;
            _num >>= 1;
        }
        return count;
    }
}
