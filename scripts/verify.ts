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
    address: '0x18E71fb1b0a1bde8e2696BA98303f3AaA0EeF2d0',
    constructorArguments: [],
  });
}

main();
