// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/INft.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Auction is Ownable {
    address public nftAddr;
    address public odsyAddr;
    uint256 auctionFeeInNative = 8;
    uint256 auctionFeeInOdsy = 4;

    struct AuctionInfo {
        uint256 startPrice;
        uint256 startAt;
        uint256 endAt;
        address creator;
    }
    mapping(uint256 => AuctionInfo) public auctionList; // {tokenId : auction_info}
    mapping(uint256 => bool) public openAuctions; // {tokenId : auction_open_state}
    mapping(uint256 => address) public highestBidder; // {tokenId : bidder_address}
    mapping(uint256 => uint256) public highestBid; // {tokenId : bid_price}

    modifier tokenExist (uint256 tokenId) {
        require(INft(nftAddr).exists(tokenId), 'Token Id does not exist.');
        _;
    }
    modifier openedAuction (uint256 tokenId) {
        require(auctionList[tokenId].startAt < block.timestamp, 'Auction is not yet started');
        require(auctionList[tokenId].endAt > block.timestamp, 'Auction is already ended.');
        require(openAuctions[tokenId], 'This auction is not yet opened.');
        _;
    }
    constructor(address nftAddr_, address odsyAddr_) {
        nftAddr = nftAddr_;
        odsyAddr = odsyAddr_;
    }

    function openAuction(uint256 tokenId, uint256 startPrice, uint256 startAt, uint256 endAt) public tokenExist(tokenId) {
        require(block.timestamp < startAt, 'Open auction: Auction start time is before now.');
        require(startAt < endAt, 'Open auction : Start time is later than end time.');
        require(!openAuctions[tokenId], 'Open auction : This token Id already opened auction');
        AuctionInfo memory temp = AuctionInfo(startPrice, startAt, endAt, msg.sender);
        auctionList[tokenId] = temp;
        openAuctions[tokenId] = true;

        highestBidder[tokenId] = msg.sender;
        highestBid[tokenId] = startPrice;
    }

    function placeBid(uint256 tokenId, uint256 bidPrice) public payable tokenExist(tokenId) openedAuction(tokenId) {
        require(msg.sender != auctionList[tokenId].creator, 'Place Bid : Auction creator can not place the bid.');
        require(bidPrice > highestBid[tokenId], 'Place Bid : Bid price has to be greater than the previous highest bid price');
        require(msg.value == bidPrice, 'Place Bid : Not enough fund');
        if(highestBidder[tokenId] != auctionList[tokenId].creator)
            payable(highestBidder[tokenId]).transfer(highestBid[tokenId]);
        highestBidder[tokenId] = msg.sender;
        highestBid[tokenId] = bidPrice;
    }

    function completeAuction(uint256 tokenId) public tokenExist(tokenId) {
        require(auctionList[tokenId].endAt <= block.timestamp, 'It is not auction ending time.');
        require(openAuctions[tokenId] == true, 'Auction is already ended or canceled.');

        AuctionInfo memory temp = AuctionInfo(0, 0, 0, address(this));
        if(auctionList[tokenId].creator == highestBidder[tokenId]) { // Nobody placed bid on this auction
            auctionList[tokenId] = temp;
        } else {
            address from = auctionList[tokenId].creator;
            address to = highestBidder[tokenId];
            INft(nftAddr).transferFrom(from, to, tokenId);
            payable(from).transfer(highestBid[tokenId]*(100-auctionFeeInNative)/100);
        }
    }

    function cancelAuction(uint256 tokenId) public tokenExist(tokenId) openedAuction(tokenId) {
        payable(highestBidder[tokenId]).transfer(highestBid[tokenId]);
        AuctionInfo memory temp = AuctionInfo(0, 0, 0, address(0));
        auctionList[tokenId] = temp;
    }
}