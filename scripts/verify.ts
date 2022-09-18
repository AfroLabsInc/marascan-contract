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
    address: '0x1b61dd09642576fe69ea66da70913fba5d6b0b3c',
    constructorArguments: [],
  });
}

main();
