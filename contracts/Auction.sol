// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/INft.sol';

contract Auction is Ownable {
    address public nftAddr;
    address public odsyAddr;
    uint256 auctionFeeInNative = 8;
    uint256 auctionFeeInOdsy = 4;

    struct AuctionInfo {
        uint256 startPrice;
        uint256 curOption;
        uint256 startAt;
        uint256 endAt;
        address creator;
    }
    mapping(uint256 => AuctionInfo) public auctionList; // {tokenId : auction_info}
    mapping(uint256 => address) public highestBidder; // {tokenId : bidder_address}
    mapping(uint256 => uint256) public highestBid; // {tokenId : bid_price}

    modifier tokenExist (uint256 tokenId) {
        require(INft(nftAddr).exists(tokenId), 'Token Id does not exist.');
        _;
    }
    modifier openedAuction (uint256 tokenId) {
        require(auctionList[tokenId].startAt < block.timestamp, 'Auction is not yet started');
        require(auctionList[tokenId].endAt > block.timestamp, 'Auction is already ended.');
        _;
    }
    constructor(address nftAddr_, address odsyAddr_) {
        nftAddr = nftAddr_;
        odsyAddr = odsyAddr_;
    }

    function openAuction(uint256 tokenId, uint256 startPrice, uint256 startAt, uint256 endAt) public tokenExist(tokenId) {
        require(block.timestamp < startAt, 'Open auction: Auction start time is before now.');
        require(startAt < endAt, 'Open auction : Start time is later than end time.');

        uint256 saleOption; // {0: sale, 1: auction}
        uint256 currencyOption; // {0: native, 1; odsy}
        (,saleOption ,currencyOption , , , , ) = INft(nftAddr).nftList(tokenId);
        require(saleOption == 0, 'This NFT is already set as auction.');

        AuctionInfo memory temp = AuctionInfo(startPrice, currencyOption, startAt, endAt, msg.sender);
        auctionList[tokenId] = temp;
        INft(nftAddr).updateSaleMethod(tokenId, 1);

        highestBidder[tokenId] = msg.sender;
        highestBid[tokenId] = startPrice;
    }

    function placeBid(uint256 tokenId, uint256 bidPrice) public payable tokenExist(tokenId) openedAuction(tokenId) {
        require(msg.sender != auctionList[tokenId].creator, 'Place Bid : Auction creator can not place the bid.');
        uint256 saleOption; // {0: sale, 1: auction}
        (,saleOption , , , , , ) = INft(nftAddr).nftList(tokenId);
        require(saleOption == 1, 'Token is in sale option.');
        require(bidPrice > highestBid[tokenId], 'Place Bid : Bid price has to be greater than the previous highest bid price');
        if(auctionList[tokenId].curOption == 0) {
            require(msg.value == bidPrice, 'Place Bid : Not enough fund');
            if(highestBidder[tokenId] != auctionList[tokenId].creator)
                payable(highestBidder[tokenId]).transfer(highestBid[tokenId]);
        } else {
            require(IERC20(odsyAddr).allowance(msg.sender, address(this)) >= bidPrice, 'Msg.sender does not allow enough $ODSY');
            if(highestBidder[tokenId] != auctionList[tokenId].creator)
                IERC20(odsyAddr).transfer(highestBidder[tokenId], highestBid[tokenId]);
            IERC20(odsyAddr).transferFrom(msg.sender, address(this), bidPrice);
        }
        highestBidder[tokenId] = msg.sender;
        highestBid[tokenId] = bidPrice;
    }

    function completeAuction(uint256 tokenId) public tokenExist(tokenId) {
        require(auctionList[tokenId].endAt <= block.timestamp, 'It is not auction ending time.');
        uint256 saleOption; // {0: sale, 1: auction}
        (,saleOption , , , , , ) = INft(nftAddr).nftList(tokenId);
        require(saleOption == 1, 'This NFT is not in auction.');

        AuctionInfo memory temp = AuctionInfo(0, 0, 0, 0, address(this));
        if(auctionList[tokenId].creator == highestBidder[tokenId]) { // Nobody placed bid on this auction
            auctionList[tokenId] = temp;
        } else {
            address from = auctionList[tokenId].creator;
            address to = highestBidder[tokenId];
            INft(nftAddr).transferFrom(from, to, tokenId);
            if(auctionList[tokenId].curOption == 0) {
                payable(from).transfer(highestBid[tokenId]*(100-auctionFeeInNative)/100);
            } else {
                IERC20(odsyAddr).transfer(from, highestBid[tokenId]*(100 - auctionFeeInOdsy)/100);
            }
            auctionList[tokenId] = temp;
        }
        INft(nftAddr).updateSaleMethod(tokenId, 0);
    }

    function cancelAuction(uint256 tokenId) public tokenExist(tokenId) openedAuction(tokenId) {
        require(msg.sender == auctionList[tokenId].creator, 'Only auction creator can cancel.');
        uint256 saleOption; // {0: sale, 1: auction}
        (,saleOption , , , , , ) = INft(nftAddr).nftList(tokenId);
        require(saleOption == 1, 'Token is in sale option.');

        if(auctionList[tokenId].creator != highestBidder[tokenId]) { // At least one placed a bid on this auction.
            if(auctionList[tokenId].curOption == 0)
                payable(highestBidder[tokenId]).transfer(highestBid[tokenId]);
            else
                IERC20(odsyAddr).transfer(highestBidder[tokenId], highestBid[tokenId]);
        }
        AuctionInfo memory temp = AuctionInfo(0, 0, 0, 0, address(0));
        auctionList[tokenId] = temp;
        INft(nftAddr).updateSaleMethod(tokenId, 0);
    }
}