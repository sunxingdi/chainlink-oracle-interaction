import { Wallet, Contract, providers } from "ethers";
import { ethers } from "hardhat";

import {
  SEPOLIA_RPC_URL,
  PRIVATE_KEY,
} from "../hardhat.config";

let provider: providers.JsonRpcProvider;
const privateKey = PRIVATE_KEY;

async function initSetting() {

  // 查询版本
  console.log("Ethers Version: ", ethers.version)

  // 设置网络
  const hre: HardhatRuntimeEnvironment = await import('hardhat');
  const networkName = hre.network.name; // 获取通过命令行传递的 --network 参数值

  if (networkName === 'sepolia') {
    provider = new ethers.JsonRpcProvider(SEPOLIA_RPC_URL);
    console.log('网络设置：使用远端RPC网络', networkName);

  } else if (networkName === 'localhost') {
    provider = new ethers.JsonRpcProvider();
    console.log('网络设置：使用本地网络...');

  }  else {
    throw new Error("网络参数错误，请检查...");
  }

  console.log("\n", '检查网络连接...');

  try {
      await provider.getBlockNumber(); // 尝试调用任意一个 provider 方法
      console.log('已连接到以太坊网络.');
  } catch (error) {
      console.log('未连接到以太坊网络：', error.message);
      process.exit()
  }  
}

//业务代码############################################################

let wallet:Wallet;

async function initialWallet() {
  console.log("\n", '初始化账户...');

  wallet = new ethers.Wallet(privateKey, provider);

  console.log('账户 A 地址：', wallet.address);
  console.log('账户 A 余额：', ethers.formatEther(await provider.getBalance(wallet.address)), "ETH");

}

async function makeDeploy() {

  const MyContract = await ethers.getContractFactory("VRFv2DirectFundingConsumer", wallet); //指定账户部署，需要用私钥初始化

  console.log("\n", "部署合约...");
  const myContract = await MyContract.deploy();
  console.log("合约地址:", myContract.target);

  const ContractInstance = await myContract.waitForDeployment();
  // console.log("\nContractInstance: \n", ContractInstance);

  const ContractTransactionResponse = await myContract.deploymentTransaction()
  console.log("\n", "返回交易信息...");
  console.log(ContractTransactionResponse);

  const txHash = ContractTransactionResponse.hash //获取交易哈希
  const txReceipt = await provider.waitForTransaction(txHash); //等待交易完成，返回交易回执
  // const txReceipt = await provider.getTransactionReceipt(txHash); //该方法有问题，不等待直接获取回执，可能交易还未完成。
  console.log("\n", "获取交易回执...");
  console.log(txReceipt);

  console.log("\n", "获取随机数...");
  const [roundID, price, startedAt, timeStamp, answeredInRound] = await myContract.requestRandomWords();

  console.log("Round ID:", roundID);
  console.log("Price:", price);
  console.log("Started At:", startedAt);
  console.log("Timestamp:", timeStamp);
  console.log("Answered in Round:", answeredInRound);  
}

async function main() {

  await initSetting();
  await initialWallet();
  await makeDeploy();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
