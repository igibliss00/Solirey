// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Solirey.sol";

contract Auction is Solirey {
    struct AuctionInfo {
        address payable beneficiary;
        // Parameters of the auction. Times are either
        // absolute unix timestamps (seconds since 1970-01-01)
        // or time periods in seconds.
        uint auctionEndTime;
        uint startingBid;
        uint256 tokenId;
        // Current state of the auction.
        address highestBidder;
        uint highestBid;
        // Allowed withdrawals of previous bids
        mapping(address => uint) pendingReturns;
        // Set to true at the end, disallows any change.
        bool ended;
    }
    
    using Counters for Counters.Counter;
    
    // mapping from item ID to AuctionInfo
    mapping(string => AuctionInfo) private _auctionInfo;

    // Events that will be emitted on changes.
    event HighestBidIncreased(string id, address bidder, uint amount);
    event AuctionEnded(string id);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// Create a simple auction with `_biddingTime` and `_startingBid`
    function createAuction(string memory id, uint _biddingTime, uint _startingBid) public {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        
        _auctionInfo[id].tokenId = newTokenId;
        _auctionInfo[id].beneficiary = payable(msg.sender);
        _auctionInfo[id].auctionEndTime = block.timestamp + _biddingTime;
        _auctionInfo[id].highestBidder = address(0);
        _auctionInfo[id].startingBid = _startingBid;
    }

    /// Bid on the auction with the value sent
    /// The value will only be refunded if the auction is not won.
    function bid(string memory id) public payable {
        require(
            block.timestamp <= _auctionInfo[id].auctionEndTime,
            "Auction already ended."
        );

        require(
            msg.value > _auctionInfo[id].highestBid,
            "Higher bid already exists."
        );
        
        require(
            msg.value > _auctionInfo[id].startingBid,
            "The bid has to be higher than the specified starting bid."
        );
        
        require(
            msg.sender != _auctionInfo[id].beneficiary,
            "You cannot bid on your own auction."
        );

        if (_auctionInfo[id].highestBid != 0) {
            _auctionInfo[id].pendingReturns[_auctionInfo[id].highestBidder] += _auctionInfo[id].highestBid;
        }
        
        _auctionInfo[id].highestBidder = msg.sender;
        _auctionInfo[id].highestBid = msg.value;
        emit HighestBidIncreased(id, msg.sender, msg.value);
    }

    function withdraw(string memory id) public returns (bool) {
        uint amount = _auctionInfo[id].pendingReturns[msg.sender];
        
        if (amount > 0) {
            _auctionInfo[id].pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                _auctionInfo[id].pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd(string memory id) public {
        require(block.timestamp >= _auctionInfo[id].auctionEndTime, "Auction has not yet ended.");

        _auctionInfo[id].ended = true;
        emit AuctionEnded(id);
    }
    
    function getTheHighestBid(string memory id) public payable {
        require(block.timestamp >= _auctionInfo[id].auctionEndTime, "Auction bidding time has not expired.");
        require(_auctionInfo[id].ended, "Auction has not yet ended.");
        require(msg.sender == _auctionInfo[id].beneficiary, "You are not the beneficiary");
        
        _auctionInfo[id].beneficiary.transfer(_auctionInfo[id].highestBid);
    }
    
    function transferToken(string memory id) public {
        require(block.timestamp >= _auctionInfo[id].auctionEndTime, "Bidding time has not expired.");
        require(_auctionInfo[id].ended, "Auction has not yet ended.");
        
        if (_auctionInfo[id].highestBidder == address(0)) {
            _auctionInfo[id].highestBidder = _auctionInfo[id].beneficiary;
        }
        
        require(msg.sender == _auctionInfo[id].highestBidder, "You are not the highest bidder");

        safeTransferFrom(address(this), _auctionInfo[id].highestBidder, _auctionInfo[id].tokenId);
    }
    
    // function onERC721Received(address, address _from, uint256 _tokenId, bytes calldata) external override returns(bytes4) {
    //     require(beneficiary == _from, "Only the beneficiary can transfer the token into the auction.");
    //     require(tokenAdded == false, "The auction already has a token.");
        
    //     nftContract = ERC721(msg.sender);
    //     tokenId = _tokenId;
    //     tokenAdded = true;

    //     return 0x150b7a02;
    // }
    
    // function onERC721Received(address, address _from, uint256 _tokenId, bytes memory) public virtual override returns (bytes4) {
    //     require(beneficiary == _from, "Only the beneficiary can transfer the token into the auction.");
    //     require(tokenAdded == false, "The auction already has a token.");
        
    //     nftContract = ERC721(msg.sender);
    //     tokenId = _tokenId;
    //     tokenAdded = true;
    //     return this.onERC721Received.selector;
    // }
}