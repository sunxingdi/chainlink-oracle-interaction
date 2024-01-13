# chainlink预言机交互实践

### chainlink交互流程

用户合约 <——> 代理合约 <——> 预言机合约 <——> 链下节点

代理合约地址（不变）：在官网查看 [chainlink 喂价合约地址](https://docs.chain.link/data-feeds/price-feeds/addresses/)

预言机合约地址（会变）：调用代理合约的aggregator方法获取。

### 场景1：链上使用智能合约获取币对价格

执行命令:
```
npx hardhat run .\scripts\onchain_getLatestPrice.ts --network sepolia
```

打印输出：
```
Ethers Version:  6.9.2
网络设置：使用远端RPC网络 sepolia

 检查网络连接...
已连接到以太坊网络.

 初始化账户...
账户 A 地址： 0x6BBC4994BFA366B19541a0252148601a9f874cD1
账户 A 余额： 1.682086088323044057 ETH

 Deploy contract...
Contract address: 0x7FF44D50F2A71eA9Ea3C5AeD54f9Bbb281DED07C

 返回交易信息:  ContractTransactionResponse {
  provider: JsonRpcProvider {},
  blockNumber: null,
  blockHash: null,
  index: undefined,
  hash: '0x9db863165716843450e9ee8f65a7ce0747597d3969f98b8833b805361fefd6a7',
  type: 2,
  to: null,
  from: '0x6BBC4994BFA366B19541a0252148601a9f874cD1',
  nonce: 30,
  gasLimit: 169783n,
  gasPrice: undefined,
  maxPriorityFeePerGas: 3n,
  maxFeePerGas: 363465583n,
  data: '0x608060405234801561001057600080fd5b50600080546001600160a01b031916731b44f3514812d835eb1bdb0acb33d3fa3351ee431790556101b2806100466000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80638e15f47314610030575b600080fd5b610038610073565b6040805169ffffffffffffffffffff968716815260208101959095528401929092526060830152909116608082015260a00160405180910390f35b60008060008060008060008060008060008054906101000a90046001600160a01b03166001600160a01b031663feaf968c6040518163ffffffff1660e01b815260040160a060405180830381865afa1580156100d3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906100f7919061012c565b939e929d50909b50995090975095505050505050565b805169ffffffffffffffffffff8116811461012757600080fd5b919050565b600080600080600060a0868803121561014457600080fd5b61014d8661010d565b94506020860151935060408601519250606086015191506101706080870161010d565b9050929550929590935056fea2646970667358221220d61e7e9ddb30617966ab0b6f01f29b761d096637e553827abdda208b94233d9364736f6c63430008140033',       
  value: 0n,
  chainId: 11155111n,
  signature: Signature { r: "0x97cdc3cc2200388be32bd481fa35e03838e3c202471c47790145def57ed015a5", s: "0x156c6acc8d699cf12345ac32d30f1b6a3aebe7861f80946f603a1854c7b0a08d", yParity: 1, networkV: null },
  accessList: []
}

 获取交易回执...
TransactionReceipt {
  provider: JsonRpcProvider {},
  to: null,
  from: '0x6BBC4994BFA366B19541a0252148601a9f874cD1',
  contractAddress: '0x7FF44D50F2A71eA9Ea3C5AeD54f9Bbb281DED07C',
  hash: '0x9db863165716843450e9ee8f65a7ce0747597d3969f98b8833b805361fefd6a7',
  index: 52,
  blockHash: '0xaac45171ee4c642c34e80eedf2edfd231cad1eb7a5621a39ccc5e242317db5fe',
  blockNumber: 5064256,
  logsBloom: '0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  gasUsed: 169783n,
  cumulativeGasUsed: 4774961n,
  gasPrice: 174202459n,
  type: 2,
  status: 1,
  root: undefined
}

 获取交易价格...
Round ID: 18446744073709560740n
Price: 4632902900000n
Started At: 1704949920n
Timestamp: 1704949920n
Answered in Round: 18446744073709560740n
```

### 场景2：链下使用Ethers获取币对价格

执行命令：
```
npx hardhat run .\scripts\offchain_getLatestPrice.ts --network sepolia
```

打印输出：
```
Ethers Version:  6.9.2
网络设置：使用远端RPC网络 sepolia

 检查网络连接...
已连接到以太坊网络.

 获取交易价格...
Latest Round Data Result(5) [
  18446744073709560740n,
  4632902900000n,
  1704949920n,
  1704949920n,
  18446744073709560740n
]
```

### 场景3：获取随机数

Chainlink VRF（Verifiable Random Function）提供了两种方式来获取随机数：订阅模式（Subscription）和直接资助模式（Direct Funding）。

- 订阅模式（Subscription）：
  
  在订阅模式下，用户创建一个订阅账户，并为其充值 LINK 代币。然后，用户在自己的智能合约中指定这个订阅 ID，并通过它来请求随机数。这种方式的优点是方便管理费用，特别是当用户有多个合约需要使用 Chainlink VRF 服务时，可以统一管理 LINK 代币。此外，它也可以减少合约的复杂性，因为合约不需要直接处理 LINK 代币的转移。

- 直接资助模式（Direct Funding）：
  
  直接资助模式下，每个合约都需要单独存有足够的 LINK 代币以支付请求随机数的费用。用户直接向合约地址发送 LINK 代币，然后合约使用这些代币来支付随机数请求的费用。这种方式使得每个合约都必须管理自己的 LINK 余额，适用于只有单个或少数几个合约需要获取随机数的情况。

#### 本次实践使用直接资助模式：

操作思路：

1. EOA向用户合约转账LINK 2~3个。
2. 用户合约调用预言机合约请求随机数。
3. 供应商调用用户合约回调函数处理随机数。
4. 注意，供应商返回随机数所需时长不定，实测1~15分钟都有可能。

执行命令：

```
npx hardhat run .\scripts\onchain_getRandomWords.ts --network sepolia
```

打印输出：

```
Ethers Version:  6.9.2
网络设置：使用远端RPC网络 sepolia

 检查网络连接...
已连接到以太坊网络.

 初始化账户...
账户 A 地址： 0x6BBC4994BFA366B19541a0252148601a9f874cD1
账户 A 余额： 0.565946193440245031 ETH

 向合约转账LINK代币...
转账LINK TxHash: 0xd6c306ed206868674b0995af448b0f3d3e886a84daf0c3eb525892ed9715e283
转账LINK确认区块: 5075702

 GasLimit估算值...
270596n

 GasLimit实际值...
811788n

 请求随机数...    
请求ID:  ContractTransactionResponse {
  provider: JsonRpcProvider {},
  blockNumber: null,
  blockHash: null,
  index: undefined,
  hash: '0x9450097063177c38227be74ee7bfe791cc099540f22a4f79416f59b717557f5a',
  type: 2,
  to: '0x44Cd3824e60B59231110DBEaC4E7509663da42eD',
  from: '0x6BBC4994BFA366B19541a0252148601a9f874cD1',
  nonce: 61,
  gasLimit: 811788n,
  gasPrice: undefined,
  maxPriorityFeePerGas: 3n,
  maxFeePerGas: 73320924605n,
  data: '0xe0c86289',
  value: 0n,
  chainId: 11155111n,
  signature: Signature { r: "0xc910a5149ed14d1248c6bcb546d6498db45cd28bf32d8856622b64761a8cb895", s: "0x4f8724e1db73b5a3c25f2370c3c7f4a5f427dda5fbd1128d9be1f42bd5791f06", yParity: 1, networkV: null },
  accessList: []
}

 正在监听，事件名：RequestFulfilled事件，合约地址：0x44Cd3824e60B59231110DBEaC4E7509663da42eD

 监听到RequestFulfilled事件...
事件参数: requestId=19891379479896905398216706642029295272050901467061918803252650984408165405179, randomWords=2490584276676312612968275103083126423355159767329552346204418801660152229311,77485594511757623740245860577823040455290703714804099043389842992508189535920, payment=1685389785781585876       
事件对象:  ContractEventPayload {
  filter: 'RequestFulfilled',
  emitter: Contract {
    target: '0x44Cd3824e60B59231110DBEaC4E7509663da42eD',
    interface: Interface {
      fragments: [Array],
      deploy: [ConstructorFragment],
      fallback: null,
      receive: false
    },
    runner: Wallet {
      provider: JsonRpcProvider {},
      address: '0x6BBC4994BFA366B19541a0252148601a9f874cD1'
    },
    filters: {},
    fallback: null,
    [Symbol(_ethersInternal_contract)]: {}
  },
  log: EventLog {
    provider: JsonRpcProvider {},
    transactionHash: '0xf7ef6fb206eccd95fa7ef94765881ef9882834659223e7e36c2cd32154420d68',
    blockHash: '0x3c62365c7c1c3d4fbba61d6e3834f834883aa659fb2313e7e64cb095c7e13e06',
    blockNumber: 5075708,
    removed: false,
    address: '0x44Cd3824e60B59231110DBEaC4E7509663da42eD',
    data: '0x2bfa1f2f1ffa3550eb3e15d9c79e16bc5ced7b477f1c3a877e325ba8375451fb00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000001763b514a19547d4000000000000000000000000000000000000000000000000000000000000000205819ee92db43f6ac2b10755b0db4e0c5cb2020bf7e4c06c21e7f9e170a7adbfab4f4ad586de409451902b4cc9feceb2dd679341ff48b99cfb31350c69c7eeb0',
    topics: [
      '0x147eb1ff0c82f87f2b03e2c43f5a36488ff63ec6b730195fde4605f612f8db51'
    ],
    index: 132,
    transactionIndex: 117,
    interface: Interface {
      fragments: [Array],
      deploy: [ConstructorFragment],
      fallback: null,
      receive: false
    },
    fragment: EventFragment {
      type: 'event',
      inputs: [Array],
      name: 'RequestFulfilled',
      anonymous: false
    },
    args: Result(3) [
      19891379479896905398216706642029295272050901467061918803252650984408165405179n,
      [Result],
      1685389785781585876n
    ]
  },
  args: Result(3) [
    19891379479896905398216706642029295272050901467061918803252650984408165405179n,
    Result(2) [
      2490584276676312612968275103083126423355159767329552346204418801660152229311n,
      77485594511757623740245860577823040455290703714804099043389842992508189535920n
    ],
    1685389785781585876n
  ],
  fragment: EventFragment {
    type: 'event',
    inputs: [ [ParamType], [ParamType], [ParamType] ],
    name: 'RequestFulfilled',
    anonymous: false
  }
}

 获取随机数...
Result(2) [
  2490584276676312612968275103083126423355159767329552346204418801660152229311n,
  77485594511757623740245860577823040455290703714804099043389842992508189535920n
]
```

### 参考文章

[chainlink 喂价合约地址](https://docs.chain.link/data-feeds/price-feeds/addresses/)

[chainlink 喂价节点网络](https://data.chain.link/)

[chainlink 可验证随机数](https://docs.chain.link/vrf/)
