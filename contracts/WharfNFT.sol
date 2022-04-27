// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Counters.sol";
import "./WharfMarketplace.sol"; // Not in use. Need to remain here due to contract upgrade.
import "./IWharfMarketplace.sol";

contract WharfNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable
{
    /**
     * @dev Token ID counter
     */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /**
     * @dev Prfix uri used in _baseURI().
     */
    string private _prefixURI;

    /**
     * @dev Marketplace contract
     */
    WharfMarketplace private _marketplace; // Not in use. Need to remain here due to contract upgrade.

    /**
     * @dev Token data structure.
     */
    struct TokenData {
        string ipfsCID;
        address minter;
        uint32 royalty; // Royalty percentage. Example: 2.5% = 2500, 100% = 100000,
        address royaltyBeneficiary; // Beneficiary for royalty
    }
    mapping(uint256 => TokenData) private _tokenData;

    /**
     * @dev Marketplace contract address
     */
    address private _marketplaceAddress;

    /**
     * @dev Constructor.
     * @param name Token name.
     * @param symbol Token symbol.
     * @param prefixURI Prefix URI.
     */
    function initialize(
        string memory name,
        string memory symbol,
        string memory prefixURI
    ) public initializer {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Ownable_init();

        _prefixURI = prefixURI;
        _tokenIdCounter.reset();
    }

    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        string memory ipfsCID = ipfsCIDOf(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, ipfsCID))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        // NFT Royalty standard interface
        bytes4 _INTERFACE_ID_ERC2981 = 0x2a55205a;
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Assign marketplace contract.
     * Permission: Contract owner.
     * @param marketplace Marketplace contract address.
     */
    function setMarketplaceContract(address marketplace) external onlyOwner {
        _marketplaceAddress = marketplace;
    }

    /**
     * @dev Getter for Marketplace contract address.
     */
    function marketplaceContract() external view returns (address) {
        return _marketplaceAddress;
    }

    /**
     * @dev Set prefix URI.
     * Permission: Contract owner.
     * @param prefixURI Prefix URI.
     */
    function setPrefixURI(string memory prefixURI) external onlyOwner {
        _prefixURI = prefixURI;
    }

    /**
     * @dev Getter for IPFS CID.
     * @param tokenId Token ID.
     */
    function ipfsCIDOf(uint256 tokenId) internal view returns (string memory) {
        return _tokenData[tokenId].ipfsCID;
    }

    /**
     * @dev Getter for royalty beneficiary
     * @param tokenId Token ID.
     */
    function royaltyBeneficiaryOf(uint256 tokenId)
        internal
        view
        returns (address)
    {
        if (_tokenData[tokenId].royaltyBeneficiary == address(0)) {
            return _tokenData[tokenId].minter;
        } else {
            return _tokenData[tokenId].royaltyBeneficiary;
        }
    }

    /**
     * @dev Getter for royalty
     * @param tokenId Token ID.
     */
    function royaltyOf(uint256 tokenId) internal view returns (uint256) {
        return _tokenData[tokenId].royalty;
    }

    /**
     * @dev Royalty info. Based on EIP-2981
     * @param tokenId Token ID.
     * @param salePrice Token ID.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(salePrice != 0, "Wharf: Sale price is 0");

        uint256 royalty = (salePrice / 100000) * royaltyOf(tokenId);
        address beneficiary = royaltyBeneficiaryOf(tokenId);
        return (beneficiary, royalty);
    }

    /**
     * @dev To set royalty beneficiary
     * @param beneficiary Beneficiary address.
     * @param tokenId Token ID.
     */
    function updateRoyaltyBeneficiary(address beneficiary, uint256 tokenId)
        external
    {
        require(_exists(tokenId), "Wharf: Query for nonexistent token");

        if (_tokenData[tokenId].royaltyBeneficiary == address(0)) {
            // Condition when beneficiary is not set
            require(
                _tokenData[tokenId].minter == _msgSender(),
                "Wharf: Caller must be token minter"
            );
        } else {
            // Only current beneficiay is allow to change to different address
            require(
                _tokenData[tokenId].royaltyBeneficiary == _msgSender(),
                "Wharf: Caller must be current royalty beneficiary"
            );
        }

        // Update token information
        _tokenData[tokenId].royaltyBeneficiary = beneficiary;
    }

    /**
     * @dev Mint token.
     * @param ipfsCID IPFS CID. Obtain from IPFS network.
     * @param royalty Royalty percentage. Royalty will be paid on every sale transaction. Example: 5% = 5000, 2.5% = 2500.
     */
    function safeMint(string memory ipfsCID, uint32 royalty) external {
        require(royalty <= 90000, "Wharf: Royalty should not be more than 90%");

        // Store TokenData information
        _tokenData[_tokenIdCounter.current()] = TokenData(
            ipfsCID,
            _msgSender(),
            royalty,
            _msgSender()
        );

        // Conduct minting
        _safeMint(_msgSender(), _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function mint(address to, uint256 tokenId) public returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    /**
     * @dev Mint token on behalf of other address.
     * @param ipfsCID IPFS CID. Obtain from IPFS network.
     * @param royalty Royalty percentage. Royalty will be paid on every sale transaction. Example: 5% = 5000, 2.5% = 2500.
     */
    function safeMintFor(
        address minter,
        string memory ipfsCID,
        uint32 royalty
    ) external {
        require(royalty <= 90000, "Wharf: Royalty should not be more than 90%");

        // Store TokenData information
        _tokenData[_tokenIdCounter.current()] = TokenData(
            ipfsCID,
            minter,
            royalty,
            minter
        );

        // Conduct minting and transfer token to _msgSender()
        _safeMint(minter, _tokenIdCounter.current());
        _safeTransfer(minter, _msgSender(), _tokenIdCounter.current(), "");

        _tokenIdCounter.increment();
    }

    /**
     * @dev To set token for Sale
     * @param tokenId Token ID.
     * @param price Token selling price in wei.
     */
    function approveMarket(uint256 tokenId, uint256 price) external {
        // Set permission
        approve(_marketplaceAddress, tokenId);

        // Call marketplace contract to set selling price
        WharfMarketplace(_marketplaceAddress).setSalePrice(tokenId, price);
    }

    /**
     * @dev Burn token.
     * Permission: Token owner and Minter.
     * @param tokenId Token ID.
     */
    function burn(uint256 tokenId) public override {
        require(_exists(tokenId), "Wharf: Query for nonexistent token");

        // Check if sender is the original minter
        require(
            _msgSender() == _tokenData[tokenId].minter,
            "Wharf: Sender is not the original minter"
        );

        // Check if sender is the current owner
        require(
            _msgSender() == ownerOf(tokenId),
            "Wharf: Sender is not the token owner"
        );

        // Cancel offer if exist
        WharfMarketplace(_marketplaceAddress).tokenBurn(tokenId);

        _burn(tokenId); // Only token owner is allow to burn
    }
}
