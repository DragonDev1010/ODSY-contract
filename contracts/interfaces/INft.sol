// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INft {
    function transferFrom ( address from, address to, uint256 tokenId ) external;
    function updateOwner(uint256 tokenId, address owner_) external;
    function nftList(uint256) external returns(string memory, uint256, uint256, uint256, uint256, address payable, address payable);
    function exists(uint256 tokenId) external view returns(bool);
    function updateSaleMethod(uint256 tokenId, uint256 sale_) external;
    function updatePrice(uint256 tokenId, uint256 price_) external;
}