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
    address: '0x6a221a5460847fa245b886ecbf00361f600e4a4c',
    constructorArguments: [],
  });
}

main();
