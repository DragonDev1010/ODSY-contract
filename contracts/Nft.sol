// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract Nft is ERC721, Ownable{
    string public baseURI;
    bool public paused;
    address public auctionAddr;

    uint256 public totalAmount;
    struct NftInfo {
        string ipfsHash;
        uint256 saleOption; // {0: sale, 1: auction}
        uint256 currencyOption; // {0: native, 1: $ODSY}
        uint256 price;
        uint256 royalty;
        address payable creator;
        address payable owner;
    }
    mapping(uint256 => NftInfo) public nftList; // {tokenId : {hash, currency, sale, price, royalty, creator, owner}}

    constructor() ERC721("Odsy NFT", "ODSY") {}
    function setPaused(bool s_) public onlyOwner {
        paused = s_;
    }

    modifier emergencyPause {
        require(!paused, "Emergency Pause");
        _;
    }

    receive() external payable {}

	function withdrawAll() external onlyOwner{
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(string memory hash_, uint256 sale, uint256 cur, uint256 price, uint256 royalty) emergencyPause public {
        // { sale: [sell, auction], cur: [native, erc20], price: {}, royalty: {}}
        _safeMint(msg.sender, totalAmount);
        NftInfo memory temp = NftInfo(hash_, sale, cur, price, royalty, payable(msg.sender), payable(msg.sender));
        nftList[totalAmount] = temp;
        totalAmount += 1;
    }

    function updateSaleMethod(uint256 tokenId, uint256 sale_) public {
        require(_exists(tokenId), 'Token Id does not exist.');
        NftInfo storage nft = nftList[tokenId];
        // require(msg.sender == nft.owner, 'Only owner can update sale method.');
        require(_isApprovedOrOwner(msg.sender, tokenId) || msg.sender == auctionAddr, "transfer caller is not owner nor approved");
        require(sale_ < 3, 'Sale option is between 0 and 2.');
        nft.saleOption = sale_;
    }

    function updatePrice(uint256 tokenId, uint256 price_) public {
        require(_exists(tokenId), 'Token Id does not exist.');
        NftInfo storage nft = nftList[tokenId];
        // require(msg.sender == nft.owner, 'Only owner can update price.');
        require(_isApprovedOrOwner(msg.sender, tokenId), "transfer caller is not owner nor approved");
        nft.price = price_;
    }

    function updateOwner(uint256 tokenId, address payable owner_) public {
        require(_exists(tokenId), 'Token Id does not exist.');
        NftInfo storage nft = nftList[tokenId];
        // require(msg.sender == nft.owner, 'Only owner can update price.');
        require(_isApprovedOrOwner(msg.sender, tokenId), "transfer caller is not owner nor approved");
        require(owner_ != address(0), 'New owner address can not be zero');
        nft.owner = owner_;
    }

    function exists(uint256 tokenId) public view returns(bool) {
        bool exist;
        exist = _exists(tokenId);
        return exist;
    }

    function setAuctionAddr(address addr_) public onlyOwner {
        auctionAddr = addr_;
    }
}