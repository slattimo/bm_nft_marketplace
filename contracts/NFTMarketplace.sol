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
    ERC721("Byte Tokens", "BYTE")
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

    // Mints an NFT that can be used for a market item
    function createToken(string memory tokenURI, uint256 price)
    public payable
    returns (uint)
    {
        _tokenIds.increment();

        // Variable that gets the current value of the tokenIds (0, 1, 2, etc.)
        uint256 newTokenId = _tokenIds.current();

        // Mint the token
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);

        // Return the newTokenId
        return newTokenId;
    }

    // Creates the market item with the minted token so it can be listed on the marketplace
    function createMarketItem(uint256 tokenId, uint256 price)
    private
    {
        // Require a certain condition, in this case price greater than 0
        require(price > 0, "Price must be at least 1");
        // Require the user sending the transaction is sending the correct amount
        require(msg.value == listingPrice, "Price must be equal to listing price");

        // Create the mapping for the market item
        // Currently no seller so it's behind the marketplace payable(msg.sender)
        // payable(address(this)) is the owner
        // Price that is going to be listed
        // Has not been sold yet so it is false
        idToMarketItem[tokenId] = MarketItem(tokenId, payable(msg.sender), payable(address(this)), price, false);
        // IERC721 Transfer method giving the ownership of the NFT to the creator
        _transfer(msg.sender, address(this), tokenId);

        // Stores the market item in transaction logs
        emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    // Allows the user to resell an NFT they have purchased
    function resellToken(uint256 tokenId, uint256 price)
    public payable
    {
        require(idToMarketItem[tokenId].owner == msg.sender, "Only NFT owner can perform this operation");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    // Creates the sale of an NFT on  the marketplace
    function createMarketSale(uint256 tokenId)
    public payable
    {
        uint price = idToMarketItem[tokenId].price;

        require(msg.value == price, "Please submit the listed price in order to complete the purchase");

        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));
        idToMarketItem[tokenId].owner = payable(msg.sender);

        _itemsSold.increment();

        // IERC721 Transfer method giving the ownership of the NFT from the seller to the buyer
        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
    }

    // Returns all current unsold market items
    function fetchMarketItems()
    public view
    returns (MarketItem[] memory)
    {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        // Empty array of datatype MarketItem with unsoldItemCount as the length
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        // Looping over the number of unsold market items created and increment if the owner is the market (address(this))
        for(uint i = 0; i < itemCount; i++)
        {
            // Check to see if the item is owned by the market
            if(idToMarketItem[i + 1].owner == address(this))
            {
                // The id of the current item being interacted with
                uint currentId = i + 1;

                // Get the mapping of the currentId to reference the market item
                MarketItem storage currentItem = idToMarketItem[currentId];

                // Add the market item to the array
                items[currentIndex] = currentItem;
                // Increment index
                currentIndex += 1;
            }
        }

        return items;
    }

    // Returns all of NFTs the user has purchased
    function fetchMyNFTs()
    public view
    returns (MarketItem[] memory)
    {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        // Looping over items that are owned by the user
        for(uint i = 0; i < totalItemCount; i++)
        {
            // Check if item is owned by the user
            if(idToMarketItem[i + 1].owner == msg.sender)
            {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++)
        {
            // Check if item is owned by the user
            if(idToMarketItem[i + 1].owner == msg.sender)
            {
                // The id of the current item being interacted with
                uint currentId = i + 1;

                // Get the mapping of the currentId to reference the market item
                MarketItem storage currentItem = idToMarketItem[currentId];

                // Add the market item to the array
                items[currentIndex] = currentItem;
                // Increment index
                currentIndex += 1;
            }
        }

        return items;
    }

    // Returns the market items listed by the user
    function fetchItemsListed()
    public view
    returns (MarketItem[] memory)
    {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount; i++)
        {
            if(idToMarketItem[i + 1].seller == msg.sender)
            {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++)
        {
            if(idToMarketItem[i + 1].seller == msg.sender)
            {
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
}