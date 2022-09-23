import { ethers, upgrades, run } from 'hardhat';
import { signTypedData, SignTypedDataVersion } from '@metamask/eth-sig-util';
const { BigNumber, providers, Wallet } = ethers;
import { ContractFactory } from 'ethers'
import abi from './abi'
import Web3 from 'web3';
const wallet = new Wallet(
  `0x00202c47ec042093c6b5225f398c689eaa8b0e8c1c63740486080b9fec34e72a`
);
const main = async () => {


  const [owner] = await ethers.getSigners();
  const signer = wallet.connect(new providers.JsonRpcProvider('https://eth-goerli.g.alchemy.com/v2/MbhgMXsdTaM8wSMpDfz5uDI-J8G_IJ3j'))
  const withdrawal = new ContractFactory(abi.abi, abi.bytecode, signer);

  const MaraScanOperations = await withdrawal.attach(
    '0x7adf4b682f671b0B6Ff5dF349d4AD5671c765c7f'
  );
  //   console.log(withdrawal.withdrawFromUser())
  const valueBefore = Math.floor(Date.now() / 1000) + 3600;
  const nonce = Web3.utils.randomHex(32);
  const dataType = {
    types: {
      EIP712Domain: [
        { name: 'name', type: 'string' },
        { name: 'version', type: 'string' },
        { name: 'chainId', type: 'uint256' },
        { name: 'verifyingContract', type: 'address' },
      ],
      TransferWithAuthorization: [
        { name: 'from', type: 'address' },
        { name: 'to', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'validAfter', type: 'uint256' },
        { name: 'validBefore', type: 'uint256' },
        { name: 'nonce', type: 'bytes32' },
      ],
    },
    domain: {
      name: 'USD Coin',
      version: '2',
      chainId: 5,
      verifyingContract: '0x07865c6E87B9F70255377e024ace6630C1Eaa37F',
    },
    primaryType: 'TransferWithAuthorization',
    message: {
      from: '0xF10dc6fee78b300A5B3AB9cc9470264265a2d6Af',
      to: '0x7adf4b682f671b0B6Ff5dF349d4AD5671c765c7f',
      value: 129252,
      validAfter: 0,
      validBefore: valueBefore, // Valid for an hour
      nonce: nonce,
    },
  };

  const signature = signTypedData({
    privateKey: Buffer.from(
      '7f81d828a1ac36d802938537e27a25d2050dd16cc0ca472bcda30bb6b7acb3cd',
      'hex'
    ),
    data: {
      types: dataType.types,
      primaryType: 'TransferWithAuthorization',
      domain: dataType.domain,
      message: dataType.message,
    },
    version: SignTypedDataVersion.V4,
  });
  const v = '0x' + signature.slice(130, 132);
  const r = signature.slice(0, 66);
  const s = '0x' + signature.slice(66, 130);
  console.log(v, r, s);

  const ress = await MaraScanOperations._gaslessTransfer(
    dataType.message.from,
    dataType.message.to,
    dataType.message.value,
    dataType.message.validAfter,
    dataType.message.validBefore,
    dataType.message.nonce,
    v,
    r,
    s
  );
  console.log(ress);
};
main();
