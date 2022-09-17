import {  run } from "hardhat";
import '@nomiclabs/hardhat-ethers'
import "@openzeppelin/hardhat-upgrades"


async function main() {
  
//   const MaraScan = await ethers.getContractFactory("MaraScan");
//   console.log("Deploying MaraScan...");
//   const contract = await upgrades.deployProxy(MaraScan);
//   await contract.deployed();
  
//   console.log("MaraScan deployed to:", contract.address);
  await run("verify:verify", {
    address: '0x593ae01AA255a5Cb080F452d5a5Aaf4f1350dE24',
    constructorArguments: [],
  });
}

main();
