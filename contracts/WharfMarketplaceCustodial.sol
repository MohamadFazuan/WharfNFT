// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WharfMarketplaceCustodial is
  Initializable,
  ContextUpgradeable,
  OwnableUpgradeable
{
  /**
   * @dev Custodial wallet
   */
  address private _marketplace;

  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @dev Function to receive Ether
   */
  receive() external payable {}

  /**
   * @dev Fallback function is called when msg.data is not empty
   */
  fallback() external payable {}

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @dev Assign marketplace contract address.
   * Permission: Contract owner.
   * @param marketplace contract address.
   */
  function setMarketplaceContract(address marketplace) external onlyOwner {
    _marketplace = marketplace;
  }

  function custodialPayment(address payable to, uint256 amount) external {
    // Only marketplace contract can call withdraw
    require(
      _marketplace == _msgSender(),
      "Custodial: Required marketplace as caller"
    );

    (bool paid, ) = to.call{ value: amount }("");
    require(paid, "Custodial: Fail to conduct payment");
  }
}
