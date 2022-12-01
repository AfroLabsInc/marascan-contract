import { ethers, upgrades, run } from "hardhat";
import '@nomiclabs/hardhat-ethers'
import "@openzeppelin/hardhat-upgrades"


async function main() {
  
  const MaraScan = await ethers.getContractFactory("MachoMara");
  console.log("Deploying MaraScan...");
  const contract = await upgrades.deployProxy(MaraScan);
  await contract.deployed();
  
  console.log("MaraScan deployed to:", contract.address);
}

main();
