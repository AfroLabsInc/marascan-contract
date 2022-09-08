import { ethers, upgrades, run } from "hardhat";
import '@nomiclabs/hardhat-ethers'
import "@openzeppelin/hardhat-upgrades"


async function main() {
  
  const MaraScan = await ethers.getContractFactory("MaraScan");
  console.log("Deploying MaraScan...");
  const contract = await upgrades.deployProxy(MaraScan);
  await contract.deployed();
  console.log("MaraScan deployed to:", contract.address);
  await run("verify:verify", {
    address: '0x91983a76772659559fd42d04d3e9661d9bb0fc63',
    constructorArguments: [],
  });
}

main();
