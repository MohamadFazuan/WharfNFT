const hre = require("hardhat");
const { upgrades } = require("hardhat");

async function main() {
  const WharfMarketplace = await hre.ethers.getContractFactory(
    "WharfMarketplace"
  );
  const wharfmarketplace = await WharfMarketplace.deploy();
  await wharfmarketplace.deployed();
  const wmtxHash = wharfmarketplace.deployTransaction.hash;
  const wmtxReceipt = await hre.ethers.provider.waitForTransaction(wmtxHash);
  console.log(
    `check your contract: https://mumbai.polygonscan.com/address/${wmtxReceipt.contractAddress}`
  );
  console.log("contract address:", wmtxReceipt.contractAddress);

  const Counters = await hre.ethers.getContractFactory("Counters");
  const counters = await Counters.deploy();
  await counters.deployed();
  const ctxHash = wharfmarketplace.deployTransaction.hash;
  const ctxReceipt = await hre.ethers.provider.waitForTransaction(ctxHash);
  console.log(
    `check your contract: https://mumbai.polygonscan.com/address/${ctxReceipt.contractAddress}`
  );
  console.log("contract address:", ctxReceipt.contractAddress);

  const WharfMarketplaceCustodial = await hre.ethers.getContractFactory(
    "WharfMarketplaceCustodial"
  );
  const wharfmarketplacecustodial = await WharfMarketplaceCustodial.deploy();
  await wharfmarketplacecustodial.deployed();
  const wmctxHash = wharfmarketplacecustodial.deployTransaction.hash;
  const wmctxReceipt = await hre.ethers.provider.waitForTransaction(wmctxHash);
  console.log(
    `check your contract: https://mumbai.polygonscan.com/address/${wmctxReceipt.contractAddress}`
  );
  console.log("contract address:", wmctxReceipt.contractAddress);

  const WharfNFT = await hre.ethers.getContractFactory("WharfNFT");
  // const wharfNFT = await WharfNFT.deploy();
  const proxy = await upgrades.deployProxy(WharfNFT,["WharfNFT","wNFT","https://ipfs.io/ipfs/"]);
  await proxy.deployed();
  // const wnfttxHash = wharfNFT.deployTransaction.hash;
  // const wnfttxReceipt = await hre.ethers.provider.waitForTransaction(wnfttxHash);
  // console.log(
  //   `check your contract: https://mumbai.polygonscan.com/address/${wnfttxReceipt.contractAddress}`
  // );
  // console.log("contract address:", wnfttxReceipt.contractAddress);
  console.log(proxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
