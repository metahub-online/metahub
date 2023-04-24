// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solidstate/contracts/interfaces/IERC1155.sol";
import "./TxnPartnerShipSupport.sol";
import "./TxnMintableMarket.sol";

contract TxnHubMarket is TxnMintableMarket {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // @notice fee‰
    uint32 private _marketFee;
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);


    struct SellList {
        bool onSale;
        uint64 price;
    }

    mapping(address => mapping(address => mapping(uint128 => SellList))) private _saleMapping;


    event SaleChangeEvent (
        address _operator,
        address indexed _seller,
        address indexed _nftContract,
        uint128 indexed _tokenId,
        bool _onSale
    );

    event TradeEvent(
        address indexed _nftContract,
        address indexed _seller,
        address _buyer,
        uint128 indexed _tokenId,
        uint32 _amount,
        uint256 _totalPrice);

    mapping(address => bool) private _observers;

    event ObserverConfigured(address indexed observer, bool enable);

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    function initialize(address priceFeedAddress, bool priceInverse_, uint8 chainDigits_) public initializer {
        _transferOwnership(_msgSender());
        _updatePriceFeed(priceFeedAddress, priceInverse_);
        _modifyChainBalanceDigits(chainDigits_);
        _marketFee = 5;
    }

    function updateMarketFee(uint32 newFee_) external onlyOperator {
        //set new market fee
        _marketFee = newFee_;
    }

    function currentMarketFee() external view onlyOperator returns (uint32 fee){
        return _marketFee;
    }

    function configObserver(address observer, bool enable) external onlyOwner {
        _observers[observer] = enable;
    }

    function _checkObserver() internal view override {
        require(_observers[_msgSender()] || _operators[_msgSender()], "Operation: permission denied");
    }

    function querySaleStatus(address seller_, address nftContractAddr_, uint128 tokenId_) external view returns (
        uint128 balance,
        uint64 price
    ){
        SellList memory sale = _saleMapping[seller_][nftContractAddr_][tokenId_];
        require(sale.onSale, "Market: not on sale");
        uint128 _balance = uint128(ITxnHubNFT(nftContractAddr_).balanceOf(seller_, tokenId_));
        require(_balance > 0, "Market: balance not enough");
        return (_balance, sale.price);
    }
    /**
        @param nftContract_ This is the address of NFT contract.
        @param tokenId_ This is the ID of NFT token.
        @param price_ This is sell single price.

    **/
    function onSale(address nftContract_,
        uint128 tokenId_,
        uint64 price_
    ) external {
        require(price_ > 0, "Market: Price must greater than 0");
        require(ITxnHubNFT(nftContract_).isTxnHubContract(), "ITxnHubNFT: not Txn Hub NFT");
        require(ITxnHubNFT(nftContract_).balanceOf(_msgSender(), tokenId_) > 0, "ITxnHubNFT: NFT balance is 0");
        _saleMapping[msg.sender][nftContract_][tokenId_] = SellList(
            true,
            price_);
        emit SaleChangeEvent(msg.sender, msg.sender, nftContract_, tokenId_, true);
    }

    function cancelSale(address nftContractAddr_, uint128 tokenId_) external returns (bool){
        require(_saleMapping[msg.sender][nftContractAddr_][tokenId_].onSale, "Market: Already canceled");
        _saleMapping[msg.sender][nftContractAddr_][tokenId_].onSale = false;
        emit SaleChangeEvent(msg.sender, msg.sender, nftContractAddr_, tokenId_, false);
        return true;
    }

    function buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) public view returns (uint256 total, uint256 fee) {
        require(_saleMapping[seller_][nftContractAddr_][tokenId_].onSale, "Market: Not on sale");
        (uint256 rate,uint8 decimals) = currentExchangeRate();
        uint256 singlePrice = _divRound(_saleMapping[seller_][nftContractAddr_][tokenId_].price * rate * (10 ** _chainDigits()), 10 ** (decimals + 2));
        uint256 totalPrice = singlePrice * amount_;
        uint256 totalFee = _divRound(totalPrice * _marketFee, 1000);
        return (totalPrice, totalFee);
    }

    /**
      @param seller_ This is the seller address
      @param nftContractAddr_ This is nft contract address
      @param tokenId_ This is nft token id
      @param amount_ This is buy amount of selling tokens
    **/
    function buyToken(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) external payable {
        (uint256 totalPrice, uint256 totalFee) = buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_);
        require(msg.sender != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        require(msg.value >= totalPrice + totalFee, "Market: Paid amount needs to be greater or equals total price.");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            msg.sender,
            tokenId_,
            amount_,
            "0x0");

        emit TradeEvent(nftContractAddr_,
            seller_,
            msg.sender,
            tokenId_,
            amount_,
            msg.value);

        // transfer totalPaid-totalFee to seller's wallet
        bool sent = seller_.send(msg.value - totalFee);
        require(sent, "Market: send value failed");

        if (ITxnHubNFT(nftContractAddr_).balanceOf(seller_, tokenId_) <= 0) {
            _saleMapping[seller_][nftContractAddr_][tokenId_].onSale = false;
            emit SaleChangeEvent(msg.sender, seller_, nftContractAddr_, tokenId_, false);
        }
        _shareNftTradeFee(nftContractAddr_, tokenId_, totalFee);
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }
}