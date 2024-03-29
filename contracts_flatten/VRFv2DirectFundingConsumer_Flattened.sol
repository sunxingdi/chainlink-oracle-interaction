// Sources flattened with hardhat v2.19.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @chainlink/contracts/src/v0.8/shared/interfaces/IOwnable.sol@v0.8.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}


// File @chainlink/contracts/src/v0.8/shared/access/ConfirmedOwnerWithProposal.sol@v0.8.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}


// File @chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol@v0.8.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}


// File @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol@v0.8.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}


// File @chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol@v0.8.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}


// File @chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol@v0.8.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;


/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}


// File contracts/VRFv2DirectFundingConsumer.sol

// Original license: SPDX_License_Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;
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
    VRFV2WrapperConsumerBase, //鑾峰彇闅忔満鏁?
    ConfirmedOwner            //鏉冮檺绠＄悊
{
    event RequestSent(uint256 requestId, uint32 numWords); //鍦ㄩ殢鏈烘暟璇锋眰鍙戦€佹椂瑙﹀彂浜嬩欢
    event RequestFulfilled(  //鍦ㄨ姹傝婊¤冻鏃惰Е鍙戜簨浠?
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus { //瀛樺偍闅忔満鏁拌姹傜姸鎬?
        uint256 paid; // amount paid in link, 闇€瑕佹敮浠樼殑LINK鏁伴噺
        bool fulfilled; // whether the request has been successfully fulfilled , 鏄惁宸叉墽琛屽畬鎴?
        uint256[] randomWords; //杩斿洖鐨勯殢鏈烘暟鏁扮粍
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */ //璇锋眰ID涓庤姹傜姸鎬佺殑鏄犲皠

    // past requests Id.
    uint256[] public requestIds;   //杩囧幓鐨勮姹侷D
    uint256 public lastRequestId;  //鏈€鏂扮殑璇锋眰ID

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000; //鎵цfulfillRandomWords鍥炶皟鍑芥暟鏃舵墍鍏佽娑堣€楃殑鏈€澶as閲忋€?

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;  //璁剧疆浜嗚姹傚湪閾句笂闇€瑕佺殑纭鏁帮紝浠ョ‘淇濆畨鍏ㄦ€э紝榛樿涓?銆?

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 2; //璁剧疆浜嗘瘡涓姹傛兂瑕佹帴鏀剁殑闅忔満鏁扮殑鏁伴噺锛岃繖閲屾槸2涓€?

    // Address LINK - hardcoded for Sepolia
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789; //Sepolia娴嬭瘯缃戠粶涓奓INK浠ｅ竵鐨勭‖缂栫爜鍦板潃銆?

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46; //Sepolia娴嬭瘯缃戠粶涓奀hainlink VRF鐨刉rapper鍚堢害鍦板潃銆?

    constructor()
        ConfirmedOwner(msg.sender) //鏉冮檺鎺у埗鍚堢害鍒濆鍖?
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) //Wrapper鍚堢害鍒濆鍖?
    {}

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        //璋冪敤VRFV2WrapperConsumerBase涓殑requestRandomness鍑芥暟鏉ュ疄闄呭彂閫侀殢鏈烘暟璇锋眰銆?
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        //璁板綍璇锋眰鐨勭姸鎬併€佹洿鏂拌姹侷D鍒楄〃銆佽缃渶鍚庝竴涓姹侷D锛屽苟涓旇Е鍙戜簡涓€涓猂equestSent浜嬩欢銆?
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

    //杩欎釜鍥炶皟鍑芥暟瑕嗙洊浜哣RFV2WrapperConsumerBase涓殑fulfillRandomWords锛屽畠鍦ㄩ殢鏈烘暟鐢熸垚鍚庤Chainlink鑺傜偣璋冪敤銆?
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found"); //妫€鏌ヨ姹傛槸鍚﹀瓨鍦ㄥ苟宸叉敮浠?
        s_requests[_requestId].fulfilled = true;            //鏇存柊璇锋眰鐨勭姸鎬?
        s_requests[_requestId].randomWords = _randomWords; //鏇存柊璇锋眰鐨勭姸鎬?
        emit RequestFulfilled( //瑙﹀彂RequestFulfilled浜嬩欢
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    //杩欎釜鍏叡鍑芥暟鍏佽澶栭儴璁块棶鐗瑰畾璇锋眰鐨勭姸鎬併€?
    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found"); //妫€鏌ヨ姹傛槸鍚﹀瓨鍦?
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);  //杩斿洖鍏充簬璇锋眰鐨勪俊鎭€?
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    //杩欎釜鍏叡鍑芥暟鍏佽鍚堢害鐨勬嫢鏈夎€呮彁鍙栧悎绾︿腑鐨凩INK浠ｅ竵銆?
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
