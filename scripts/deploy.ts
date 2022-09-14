import { ethers, upgrades, run } from "hardhat";
import '@nomiclabs/hardhat-ethers'
import "@openzeppelin/hardhat-upgrades"


async function main() {
  
  // const MaraScan = await ethers.getContractFactory("MaraScan");
  // console.log("Deploying MaraScan...");
  // const contract = await upgrades.deployProxy(MaraScan);
  // await contract.deployed();
  
  // console.log("MaraScan deployed to:", contract.address);
  await run("verify:verify", {
    address: '0x1780801CEd6FCcCcff830d4DBcD8eC453aA75880',
    constructorArguments: [],
  });
}

main();
