// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/INft.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Trade is Ownable {
    uint256 public tradeFeeInNative = 8;
    uint256 public tradeFeeInOdsy = 4;
    address public nftAddress;
    address public odsyAddress;
    address public wrapEthAddr;

    modifier tokenExist (uint256 tokenId) {
        require(INft(nftAddress).exists(tokenId), 'Token Id does not exist.');
        _;
    }

    constructor(address nft_, address odsy_) { nftAddress = nft_; odsyAddress = odsy_; }

    receive() external payable {}
    function withdrawAll() external onlyOwner{
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function buy(uint256 tokenId) public payable tokenExist(tokenId) {
        uint256 saleOption; // {0: sale, 1: auction}
        uint256 currencyOption; // {0: native, 1; odsy}
        uint256 price;
        uint256 royalty;
        address payable creator;
        address payable ownerAddr;
        (,saleOption ,currencyOption , price, royalty, creator, ownerAddr) = INft(nftAddress).nftList(tokenId);
        require(msg.sender != ownerAddr, 'Owner can not buy his own NFT');
        require(saleOption == 0, 'NFT is in auction.');
        if(currencyOption == 0) {
            require(msg.value == price, 'Pay not enough.');
            if(ownerAddr == creator)
                ownerAddr.transfer(price*(100-tradeFeeInNative)/100);
            else {
                ownerAddr.transfer(price*(100-tradeFeeInNative-royalty)/100);
                creator.transfer(price*royalty/100);
            }
        } else if (currencyOption == 1) {
            require(IERC20(odsyAddress).allowance(msg.sender, address(this)) >= price, 'Buyer does not approve enough $ODSY.');
            if(ownerAddr == creator)
                IERC20(odsyAddress).transferFrom(msg.sender, ownerAddr, (price*(100-tradeFeeInOdsy)/100));
            else {
                IERC20(odsyAddress).transferFrom(msg.sender, ownerAddr, (price*(100-tradeFeeInOdsy-royalty)/100));
                IERC20(odsyAddress).transferFrom(msg.sender, creator, (price*royalty/100));
            }
        }

        INft(nftAddress).updateOwner(tokenId, msg.sender);
        INft(nftAddress).transferFrom(ownerAddr, msg.sender, tokenId);
    }

    function acceptOffer(uint256 tokenId, uint256 offerPrice, address buyer) public payable tokenExist(tokenId) {
        uint256 saleOption; // {0: sale, 1: auction}
        uint256 currencyOption; // {0: native, 1; odsy}
        uint256 royalty;
        address payable creator;
        address payable ownerAddr;
        (,saleOption ,currencyOption , , royalty, creator, ownerAddr) = INft(nftAddress).nftList(tokenId);

        require(msg.sender == ownerAddr, 'Only owner can accept offer.');
        require(saleOption == 0, 'NFT is in auction.');

        address tokenAddr;
        uint256 tradeFee;
        if(currencyOption == 0) {
            tokenAddr = wrapEthAddr;
            tradeFee = tradeFeeInNative;
        } else {
            tokenAddr = odsyAddress;
            tradeFee = tradeFeeInOdsy;
        }

        require(IERC20(tokenAddr).allowance(buyer, address(this)) >= offerPrice, 'Buyer does not approve enough $ODSY.');
        if(ownerAddr == creator)
            IERC20(tokenAddr).transferFrom(buyer, ownerAddr, (offerPrice*(100-tradeFee)/100));
        else {
            IERC20(tokenAddr).transferFrom(buyer, ownerAddr, (offerPrice*(100-tradeFee-royalty)/100));
            IERC20(tokenAddr).transferFrom(buyer, creator, (offerPrice*royalty/100));
        }
    }

    function setTradeFeeInNative (uint256 fee_) public onlyOwner { tradeFeeInNative = fee_; }
    function setTradeFeeInOdsy (uint256 fee_) public onlyOwner { tradeFeeInOdsy = fee_; }
    function updateNftAddress (address addr_) public onlyOwner { nftAddress = addr_; }
    function setWrapEthAddr (address addr_) public onlyOwner { wrapEthAddr = addr_; }
}