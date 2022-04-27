// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WharfNFT.sol";
import "./WharfMarketplaceCustodial.sol";

contract WharfMarketplace is
  Initializable,
  ContextUpgradeable,
  OwnableUpgradeable
{
  /**
   * @dev Wharf NFT contract
   */
  WharfNFT private _wharfNFT;

  /**
   * @dev To map tokenId to price
   */
  mapping(uint256 => uint256) private _tokenPrice;

  /**
   * @dev Marketplace fee
   */
  uint32 private _fee;

  /**
   * @dev To map tokenId to offer
   */
  struct TokenOffer {
    address offerFrom;
    uint256 amount;
  }
  mapping(uint256 => TokenOffer) private _tokenOffer;

  /**
   * @dev Custodial wallet
   */
  address payable private _custodial;

  /**
   * @dev Marketplace event
   */
  event Sold(
    uint256 indexed tokenId,
    address seller,
    address buyer,
    uint256 price
  );
  event PriceUpdated(uint256 indexed tokenId, address seller, uint256 price);
  event OfferSubmitted(uint256 indexed tokenId, address buyer, uint256 price);
  event OfferCanceled(uint256 indexed tokenId, address buyer);
  event OfferAccepted(uint256 indexed tokenId, address buyer);

  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @dev Assign Wharf NFT contract.
   * Permission: Contract owner.
   * @param wharfAddress Wharf contract address.
   */
  function setWharfNFTContract(address wharfAddress) external onlyOwner {
    _wharfNFT = WharfNFT(wharfAddress);
  }

  /**
   * @dev Getter for Wharf NFT contract address.
   */
  function wharfNFTContract() external view returns (address) {
    return address(_wharfNFT);
  }

  /**
   * @dev Assign custodial wallet contract.
   * Permission: Contract owner.
   * @param custodialAddress contract address.
   */
  function setCustodialWallet(address custodialAddress) external onlyOwner {
    _custodial = payable(custodialAddress);
  }

  /**
   * @dev Set token selling price.
   * @param tokenId Token ID.
   * @param price Token selling price.
   */
  function setSalePrice(uint256 tokenId, uint256 price) external {
    // Check for approval
    require(
      _wharfNFT.getApproved(tokenId) == address(this),
      "Marketplace: Require owner approval"
    );

    // Caller must be token owner or Wharf address
    require(
      (_wharfNFT.ownerOf(tokenId) == _msgSender()) ||
        (address(_wharfNFT) == _msgSender()),
      "Marketplace: Caller must be a token owner or from Wharf address"
    );

    // Minimum selling price is 0.01 ether
    require(
      price >= 10000000000000000,
      "Marketplace: Selling price does not met minimum requirement"
    );

    // Assign price value
    _tokenPrice[tokenId] = price;

    // Emit event
    emit PriceUpdated(tokenId, _wharfNFT.ownerOf(tokenId), price);
  }

  /**
   * @dev Getter for selling price.
   * @param tokenId Token ID.
   */
  function salePrice(uint256 tokenId) external view returns (uint256) {
    return _tokenPrice[tokenId];
  }

  /**
   * @dev Set fee imposed to selling token.
   * @param __fee Fee.
   */
  function setFee(uint32 __fee) external onlyOwner {
    _fee = __fee;
  }

  /**
   * @dev Getter for current fee.
   */
  function fee() external view returns (uint32) {
    return _fee;
  }

  /**
   * @dev Purchase a token.
   * @param tokenId Token ID.
   */
  function purchase(uint256 tokenId) external payable {
    // Check for approval
    require(
      _wharfNFT.getApproved(tokenId) == address(this),
      "Marketplace: Require owner approval"
    );

    // Not allow to purchase own token
    require(
      _wharfNFT.ownerOf(tokenId) != _msgSender(),
      "Marketplace: Token is owned by the caller"
    );

    // Minimum selling price is 0.01 ether
    require(
      _tokenPrice[tokenId] >= 10000000000000000,
      "Marketplace: Selling price does not met minimum requirement"
    );

    uint256 sellingPrice = _tokenPrice[tokenId];
    uint256 netFee = (sellingPrice / 100000) * _fee;

    // Payment should be more than the asking price
    require(msg.value >= sellingPrice, "Marketplace: Payment not enough");

    // Royalty infomation based on EIP-2981
    uint256 netRoyalty;
    address minter;
    (minter, netRoyalty) = _wharfNFT.royaltyInfo(tokenId, sellingPrice);

    // Royalty payment
    address payable creator = payable(minter);
    (bool paidMinter, ) = creator.call{ value: netRoyalty }("");
    require(paidMinter, "Marketplace: Fail to transfer payment to minter");

    // Seller earnings after deduct royalty and fee
    address payable seller = payable(_wharfNFT.ownerOf(tokenId));
    (bool paidSeller, ) = seller.call{
      value: (sellingPrice - netRoyalty - netFee)
    }("");
    require(paidSeller, "Marketplace: Fail to transfer payment to seller");

    // Marketplace earnings
    address payable owner = payable(owner());
    (bool paidOwner, ) = owner.call{ value: netFee }("");
    require(
      paidOwner,
      "Marketplace: Fail to transfer payment to contract owner"
    );

    // Conduct token transfer
    _wharfNFT.safeTransferFrom(
      _wharfNFT.ownerOf(tokenId),
      _msgSender(),
      tokenId
    );

    // Reset sale price back to zero
    _tokenPrice[tokenId] = 0;

    // Emit event
    emit Sold(tokenId, seller, _msgSender(), sellingPrice);
  }

  /**
   * @dev Make an offer to a token.
   * @param tokenId Token ID.
   */
  function makeOffer(uint256 tokenId) external payable {
    // Not allow to offer own token
    require(
      _wharfNFT.ownerOf(tokenId) != _msgSender(),
      "Marketplace: Token is owned by the caller"
    );

    // Check for approval
    require(
      _wharfNFT.getApproved(tokenId) == address(this),
      "Marketplace: Require owner approval"
    );

    // Minimum offer is 0.01 ether
    require(
      msg.value >= 10000000000000000,
      "Marketplace: Offer does not met minimum requirement"
    );

    // Check if existing bidder exist
    address payable currentBidder = payable(_tokenOffer[tokenId].offerFrom);
    if (currentBidder == address(0)) {
      // No offer exist
      // Minimum offer is 0.01 ether
      require(
        msg.value >= 10000000000000000,
        "Marketplace: Offer does not met minimum requirement"
      );
    } else {
      // Contain existing offer
      // New offer should be 10% or higher
      uint256 currentOffer = _tokenOffer[tokenId].amount;
      uint256 acceptedOffer = (currentOffer / 100) * 110;
      require(
        msg.value >= acceptedOffer,
        "Marketplace: Offer does not met minimum requirement"
      );

      // Refund previous bidder
      WharfMarketplaceCustodial _custodialContract = WharfMarketplaceCustodial(
        _custodial
      );
      _custodialContract.custodialPayment(currentBidder, currentOffer);
    }

    // Custodial contract to hold payable amount
    (bool custodial, ) = _custodial.call{ value: msg.value }("");
    require(
      custodial,
      "Marketplace: Fail to transfer payment to custodial contract"
    );

    // Store offer information
    _tokenOffer[tokenId] = TokenOffer(_msgSender(), msg.value);

    // Emit offer event
    emit OfferSubmitted(tokenId, _msgSender(), msg.value);
  }

  /**
   * @dev Cancel an offer from an existing token.
   * @param tokenId Token ID.
   */
  function cancelOffer(uint256 tokenId) external {
    // Not allow the cancelling offer of own token
    require(
      _wharfNFT.ownerOf(tokenId) != _msgSender(),
      "Marketplace: Token is owned by the caller"
    );

    // Only can cancel offer from the same sender address
    require(
      _tokenOffer[tokenId].offerFrom == _msgSender(),
      "Marketplace: Unauthorize offer cancellation"
    );

    // Conduct refund
    address payable sender = payable(_msgSender());
    WharfMarketplaceCustodial _custodialContract = WharfMarketplaceCustodial(_custodial);
    _custodialContract.custodialPayment(sender, _tokenOffer[tokenId].amount);

    // Update offer information
    _tokenOffer[tokenId] = TokenOffer(address(0), 0);

    // Emit offer cancel event
    emit OfferCanceled(tokenId, _msgSender());
  }

  /**
   * @dev Cancel an offer when token is burn.
   * @param tokenId Token ID.
   */
  function tokenBurn(uint256 tokenId) external {
    // Only allow call from Wharf ERC-721 contract
    require(
      _msgSender() == address(_wharfNFT),
      "Marketplace: Unauthorize function call"
    );

    // Conduct refund to offeror
    address payable currentBidder = payable(_tokenOffer[tokenId].offerFrom);
    if (currentBidder != address(0)) {
      // Refund previous bidder
      WharfMarketplaceCustodial _custodialContract = WharfMarketplaceCustodial(
        _custodial
      );
      uint256 currentOffer = _tokenOffer[tokenId].amount;
      _custodialContract.custodialPayment(currentBidder, currentOffer);

      // Update offer information
      _tokenOffer[tokenId] = TokenOffer(address(0), 0);

      // Emit offer cancel event
      emit OfferCanceled(tokenId, _msgSender());
    }
  }

  /**
   * @dev Cancel an offer from an existing token.
   * @param tokenId Token ID.
   */
  function acceptOffer(uint256 tokenId) external {
    // Only can accept offer if token is owned by sender
    require(
      _wharfNFT.ownerOf(tokenId) == _msgSender(),
      "Marketplace: Token is owned by the caller"
    );

    // Check for approval
    require(
      _wharfNFT.getApproved(tokenId) == address(this),
      "Marketplace: Require owner approval"
    );

    uint256 currentOffer = _tokenOffer[tokenId].amount;
    address buyer = _tokenOffer[tokenId].offerFrom;
    uint256 netFee = (currentOffer / 100000) * _fee;

    // Royalty infomation based on EIP-2981
    uint256 netRoyalty;
    address minter;
    (minter, netRoyalty) = _wharfNFT.royaltyInfo(tokenId, currentOffer);

    // Custodial wallet
    WharfMarketplaceCustodial _custodialContract = WharfMarketplaceCustodial(_custodial);

    // Royalty payment
    address payable creator = payable(minter);
    _custodialContract.custodialPayment(creator, netRoyalty);

    // Seller earnings after deduct royalty and fee
    address payable seller = payable(_wharfNFT.ownerOf(tokenId));
    _custodialContract.custodialPayment(
      seller,
      (currentOffer - netRoyalty - netFee)
    );

    // Marketplace earnings
    address payable owner = payable(owner());
    _custodialContract.custodialPayment(owner, netFee);

    // Conduct token transfer by current owner
    _wharfNFT.safeTransferFrom(_msgSender(), buyer, tokenId);

    // Reset sale price back to zero
    _tokenPrice[tokenId] = 0;

    // Update offer information
    _tokenOffer[tokenId] = TokenOffer(address(0), 0);
    emit OfferAccepted(tokenId, buyer);

    // Emit event
    emit Sold(tokenId, seller, buyer, currentOffer);
  }
}
