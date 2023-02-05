// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Using ERC721 standard
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

// Creating the contract ->Inherited from ERC21URIStorage
contract NFTMarketplace is ERC721URIStorage
{
    // Allows the contract to use the counter utility
    using Counters for Counters.Counter;
    
    // When the first token is minted it will get a value of zero, then one, etc.
    // This will increment the token IDs
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    // Fee to list an NFT on the marketplace
    uint256 listingPrice = 0.025 ether;

    // The owner of the contract
    // Earns a commission on every item sold
    address payable owner;

    // Keeps all the items that have been created
    // Pass in the integer that is the item ID and it returns a market item
    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem 
    {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // Used when a market item has been created
    event MarketItemCreated
    (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // Set the owner as the one deploying the contract
    constructor()
    {
        owner = payable(msg.sender);
    }

    // Updates the listing price of the contract
    function updateListingPrice(uint _listingPrice)
    public payable
    {
        require(owner == msg.sender, "Only marketplace owner can update the listing price");

        listingPrice = _listingPrice;
    }

    // Returns the listing price of the contract
    function getListingPrice()
    public view
    returns (uint256)
    {
        return listingPrice;
    }

    // Mints a token that can be listed on the marketplace
    function createToken(string memory tokenURI, uint256 price)
    public payable
    returns (uint)
    {
        _tokenIds.increment();

        // Variable that gets the current value of the tokenIds (0, 1, 2, etc.)
        uint256 newTokenId= _tokenIds.current();

        // Mint the token
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);

        // Return the newTokenId
        return newTokenId;
    }
}