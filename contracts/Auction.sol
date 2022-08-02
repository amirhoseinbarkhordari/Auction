// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Auction {

  //declare variables
  address payable beneficiary;
  address Owner;
  address highestBidder;
  address [] usersAddress;
  uint auctionEndingtime;
  uint highestBid;
  //value of bid any user
  mapping (address => uint) pendingBids;
  bool private auctionEnded=false;

  //events
  event highestBidding(address bidder, uint value);
  event declareHighestBidder(address bidder, uint value);

  //constructor of contract
  //_beneficiary : Address of beneficiary that want auction on them
  //_biddingTime : Auction end time
  constructor() {
    beneficiary = payable(msg.sender);
    auctionEndingtime = block.timestamp + 10 days;
  }

  //GethighestBidder function : Return highestBidder.
  function GethighestBidder() view public returns(address){
    return highestBidder;
  }

  //GethighestBid function : Return highestBid.
  function GethighestBid() view public returns(uint){
    return highestBid;
  }

  //Sethighest function : Set highestBid & highestBidder.
  function Sethighest(address _highestBidder,uint _highestBid) private {
    highestBid=_highestBid;
    highestBidder=_highestBidder;
  }

  //CheckNewUSer function : If new user send transaction, his/her address add to usersAddress array.
  function CheckNewUSer(address _UserAddress) view private returns(bool){
    for (uint i = 0; i < usersAddress.length; i++) {
      if(usersAddress[i]==_UserAddress)
        return false;
    }
    return true;
  }

  //removeUser function : Remove user address from usersAddress array.
  function removeUser(address _UserAddress) private returns(bool){
    for (uint i = 0; i < usersAddress.length; i++) {
      if(_UserAddress == usersAddress[i]){
        delete usersAddress[i];
        return true;
      }
    }
    return false;
  }  

  //findHighestBidder function : Find and return HighestBidder address.
  function findHighestBidder() private view returns(address){
    address _highestBidder = usersAddress[0];
    uint _highestBid = pendingBids[_highestBidder];
    for (uint i = 1; i < usersAddress.length; i++) {
      if(_highestBid < pendingBids[usersAddress[i]]){
        _highestBid=pendingBids[usersAddress[i]];
        _highestBidder=usersAddress[i];
      }
    }
    return _highestBidder;
  }

  //Bid function : Before Auction end time this function checks if a user suggest a higher cost that Changes value of variables
  function bid() payable external{
    require(auctionEndingtime < block.timestamp, 'Auction already finished');
    require(!auctionEnded, 'Ending Auction already called');

    if(CheckNewUSer(msg.sender))
      usersAddress.push(msg.sender);

    pendingBids[msg.sender] += msg.value;   
    require(pendingBids[msg.sender] > highestBid, 'Bid Not High Enough');
    
    Sethighest(msg.sender,pendingBids[msg.sender]);
    emit highestBidding(highestBidder, highestBid);
  }

  //Withdraw function : Withdraw own value by users
  function withdraw() external{
    uint _value = pendingBids[msg.sender];

    if(_value > 0){  
      pendingBids[msg.sender] = 0;
      bool result = payable(msg.sender).send(_value);
      if(!result){
        pendingBids[msg.sender] = _value;
      }
      else{
        bool resultRemove = removeUser(msg.sender);
        if(GethighestBidder() == msg.sender && resultRemove){
          address highestAddress = findHighestBidder();
          Sethighest(highestAddress,pendingBids[highestAddress]);
        }
      }    
    }
  }

 //DeclareAuctionEnd function : Final announcement of the winner of the auction
  function DeclareAuctionEnd() external{
    require(auctionEndingtime > block.timestamp, 'Auction not ended yet');
    require(!auctionEnded, 'Ending Auction already called');
    auctionEnded = true;
    emit declareHighestBidder(highestBidder, highestBid);
    beneficiary.transfer(highestBid);
    pendingBids[highestBidder]=0;
  }
}