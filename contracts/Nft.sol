// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract Nft is ERC721, Ownable{
    string public baseURI;
    bool public paused;

    uint256 public maxOwned = 10000;
    uint256 public totalAmount;

    struct NftInfo {
        bytes32 ipfsHash;
        uint256 currencyOption;
        uint256 saleOption;
        uint256 price;
        address creator;
        address owner;
    }
    NftInfo[] public nftList;

    event NftMinted(address minter, uint256 tokenId, bytes32 ipfsHash, uint256 currencyOption, uint256 saleOption, uint256 price, address creator, uint256 created);

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

    function mint(bytes32 hash_, uint256 curOpt, uint256 saleOpt, uint256 price) public {
        require(balanceOf(msg.sender) < maxOwned, "Maximumlly can own 10,000 NFTs");
        _safeMint(msg.sender, totalAmount);

        NftInfo memory temp = NftInfo(hash_, curOpt, saleOpt, price, msg.sender, msg.sender);
        nftList.push(temp);

        emit NftMinted(msg.sender, totalAmount, hash_, curOpt, saleOpt, price, msg.sender, block.timestamp);

        totalAmount += 1;
    }
}