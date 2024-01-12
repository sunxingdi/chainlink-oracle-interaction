// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract VRFv2DirectFundingConsumer is
    VRFV2WrapperConsumerBase, //获取随机数
    ConfirmedOwner            //权限管理
{
    event RequestSent(uint256 requestId, uint32 numWords); //在随机数请求发送时触发事件
    event RequestFulfilled(  //在请求被满足时触发事件
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus { //存储随机数请求状态
        uint256 paid; // amount paid in link, 需要支付的LINK数量
        bool fulfilled; // whether the request has been successfully fulfilled , 是否已执行完成
        uint256[] randomWords; //返回的随机数数组
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */ //请求ID与请求状态的映射

    // past requests Id.
    uint256[] public requestIds;   //过去的请求ID
    uint256 public lastRequestId;  //最新的请求ID

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000; //执行fulfillRandomWords回调函数时所允许消耗的最大gas量。

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;  //设置了请求在链上需要的确认数，以确保安全性，默认为3。

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 2; //设置了每个请求想要接收的随机数的数量，这里是2个。

    // Address LINK - hardcoded for Sepolia
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789; //Sepolia测试网络上LINK代币的硬编码地址。

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46; //Sepolia测试网络上Chainlink VRF的Wrapper合约地址。

    constructor()
        ConfirmedOwner(msg.sender) //权限控制合约初始化
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) //Wrapper合约初始化
    {}

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        //调用VRFV2WrapperConsumerBase中的requestRandomness函数来实际发送随机数请求。
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        //记录请求的状态、更新请求ID列表、设置最后一个请求ID，并且触发了一个RequestSent事件。
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    //这个回调函数覆盖了VRFV2WrapperConsumerBase中的fulfillRandomWords，它在随机数生成后被Chainlink节点调用。
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found"); //检查请求是否存在并已支付
        s_requests[_requestId].fulfilled = true;            //更新请求的状态
        s_requests[_requestId].randomWords = _randomWords; //更新请求的状态
        emit RequestFulfilled( //触发RequestFulfilled事件
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    //这个公共函数允许外部访问特定请求的状态。
    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found"); //检查请求是否存在
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);  //返回关于请求的信息。
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    //这个公共函数允许合约的拥有者提取合约中的LINK代币。
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
