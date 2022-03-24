// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract Nft is ERC721, Ownable{
    string public baseURI;
    bool public paused;

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
}