//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    string public lot;
    address payable public immutable seller;
    bool public started;
    bool public ended;
    uint256 public highestBid;
    address public highestBidder;
    mapping(address => uint256) public bidders;
    bool lockedReentrancy;

    constructor(string memory _lot, uint256 _startPrice) {
        seller = payable(msg.sender);
        lot = _lot;
        highestBid = _startPrice;
        started = true;
        ended = false;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "You are not a seller");
        _;
    }

    modifier isStarted() {
        require(started, "Auction not started");
        _;
    }

    modifier notEnded() {
        require(!ended, "Auction has ended");
        _;
    }

    modifier noReentrancy() {
        require(!lockedReentrancy, "Stop Reentrancy");
        lockedReentrancy = true;
        _;
        lockedReentrancy = false;
    }

    function placeBid() external payable isStarted notEnded {
        // проверяет что ставка выше предыдущей
        require(msg.value > highestBid, "your bid too low");

        highestBid = msg.value;
        highestBidder = msg.sender;

        // записывает в меппинг bids какую ставку сделал покупатель
        bidders[msg.sender] += msg.value;
    }

    function stop() public isStarted onlySeller {
        require(!ended, "Auction is ended");
        ended = true;
        seller.transfer(highestBid);
    }

    // возвращает покупателю сделанную ставку в случае если его ставку перебили
    function refund() external payable noReentrancy{


        uint refundAmount = bidders[msg.sender];
        require(refundAmount > 0, "you did not participate in the auction");
        payable(msg.sender).transfer(refundAmount);
        bidders[msg.sender] = 0;


    }

}
