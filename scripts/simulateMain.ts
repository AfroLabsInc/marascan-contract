import { ethers, upgrades, run } from "hardhat";
import { signTypedData, SignTypedDataVersion } from "@metamask/eth-sig-util";
const { BigNumber, providers, Wallet } = ethers;
import { ContractFactory } from "ethers";
import abi from "./mainabi";
import Web3 from "web3";
const wallet = new Wallet(
  process.env.PRIVATE_KEY!
);
const main = async () => {
  const [owner] = await ethers.getSigners();
  const signer = wallet.connect(
    new providers.JsonRpcProvider(
      "https://eth-goerli.g.alchemy.com/v2/MbhgMXsdTaM8wSMpDfz5uDI-J8G_IJ3j"
    )
  );
  const MaraScan = new ContractFactory(abi.abi, abi.bytecode, signer);

  const MaraScanOperations = await MaraScan.attach(
    "0x203A0e564f5d45B31ae820F4BBf7621861518b59"
  );
  //   console.log(MaraScanOperations)
 const res = await MaraScanOperations.donate(
    2000000,
    31,
    [
        [
            "0x9A6b282Df581F49C986C700CAe2AD5f8170b941c",
            6
        ],
        [
            "0x7CF4E3F8842dBB81C76dBcdbb720Ba020f7A3e8E",
            6
        ]
    ],
    12,
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    true
  );
  console.log(res)
};
main();
