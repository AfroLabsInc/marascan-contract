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
    address: '0x8Ebe7975a938f82055ffc0C865553C9D7880b334',
    constructorArguments: [],
  });
}

main();
