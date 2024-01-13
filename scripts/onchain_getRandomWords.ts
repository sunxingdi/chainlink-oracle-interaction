import { Wallet, Contract, providers } from "ethers";
import { ethers } from "hardhat";

import { VRFv2DirectFundingConsumerABI } from "./contract_abi";

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

async function makeRequest() {

  // 方法1：使用工厂部署合约
  // const MyContract = await ethers.getContractFactory("VRFv2DirectFundingConsumer", wallet); //指定账户部署，需要用私钥初始化
  // console.log("\n", "部署合约...");
  // const myContract = await MyContract.deploy();
  // console.log("合约地址:", myContract.target);

  // const ContractInstance = await myContract.waitForDeployment();
  // // console.log("\nContractInstance: \n", ContractInstance);

  // const ContractTransactionResponse = await myContract.deploymentTransaction()
  // console.log("\n", "返回交易信息...");
  // console.log(ContractTransactionResponse);

  // const txHash = ContractTransactionResponse.hash //获取交易哈希
  // const txReceipt = await provider.waitForTransaction(txHash); //等待交易完成，返回交易回执
  // // const txReceipt = await provider.getTransactionReceipt(txHash); //该方法有问题，不等待直接获取回执，可能交易还未完成。
  // console.log("\n", "获取交易回执...");
  // console.log(txReceipt);

  // 方法2：使用ABI创建合约
  const VRFv2DirectFundingConsumerAddr = "0x44Cd3824e60B59231110DBEaC4E7509663da42eD";
  const myContract = new ethers.Contract(VRFv2DirectFundingConsumerAddr, VRFv2DirectFundingConsumerABI, wallet);

  console.log("\n", "向合约转账LINK代币...");
  // LINK代币合约地址和ABI（只需包括transfer函数）
  const linkTokenAddress = "0x779877A7B0D9E8603169DdbD7836e478b4624789"; // Sepolia LINK代币合约地址
  const linkTokenAbi = [
    "function transfer(address to, uint amount) returns (bool)",
  ];
  // 创建代币合约实例
  const linkTokenContract = new ethers.Contract(linkTokenAddress, linkTokenAbi, wallet);
  // 接收者地址和转账数量
  const toAddress = myContract.target; // 接收LINK代币的合约地址
  const amount = ethers.parseUnits("10", 18); // LINK代币精度：18位。获取随机数需要消耗5个LINK左右。

  // 调用transfer函数发送代币
  const transactionResponse = await linkTokenContract.transfer(toAddress, amount);
  console.log(`转账LINK TxHash: ${transactionResponse.hash}`);

  // 等待交易被挖掘
  const receipt = await transactionResponse.wait();
  console.log(`转账LINK确认区块: ${receipt.blockNumber}`);

  // 估算调用合约函数所需的gas
  const estimatedGas = await myContract.requestRandomWords.estimateGas();
  console.log("\n", "GasLimit估算值...");
  console.log(estimatedGas);

  const gasLimitWithBuffer = estimatedGas + estimatedGas * 200n / 100n; //BigInt类型
  console.log("\n", "GasLimit实际值...");
  console.log(gasLimitWithBuffer);

  console.log("\n", "请求随机数...");
  const requestId = await myContract.requestRandomWords({gasLimit: gasLimitWithBuffer});
  console.log("请求ID: ", requestId);

  // 监控 RequestFulfilled 事件
  console.log("\n", `正在监听，事件名：RequestFulfilled事件，合约地址：${myContract.target}`);
  // const eventFilter = myContract.filters.RequestFulfilled();
  myContract.once("RequestFulfilled", async (requestId: number, randomWords: number[], payment:number, event) => {

    console.log("\n", `监听到RequestFulfilled事件...`);
    console.log(`事件参数: requestId=${requestId}, randomWords=${randomWords}, payment=${payment}`);
    console.log(`事件对象: `, event);

  // 输出获取到的数据
  const lastRequestId = await myContract.lastRequestId();
  const RequestStatus = await myContract.getRequestStatus(lastRequestId);
  console.log("\n", `获取随机数...`);
  console.log(RequestStatus.randomWords);

  });


}

async function main() {

  await initSetting();
  await initialWallet();
  await makeRequest();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
