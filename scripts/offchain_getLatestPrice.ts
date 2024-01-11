import { providers } from "ethers";
import { ethers } from "hardhat";

import { aggregatorV3InterfaceABI } from "./contract_abi";

import {
  SEPOLIA_RPC_URL,
} from "../hardhat.config";

let provider: providers.JsonRpcProvider;

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

async function getLatestPrice() {
  
  /**
   * Network: Sepolia
   * Aggregator: BTC/USD
   * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
   */

  const AggregatorAddr = "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43"

  const myContract = new ethers.Contract(AggregatorAddr, aggregatorV3InterfaceABI, provider);

  const RoundData = await myContract.latestRoundData();

  console.log("\n", "获取交易价格...");
  console.log("Latest Round Data", RoundData)

}

async function main() {

  await initSetting();
  await getLatestPrice();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
