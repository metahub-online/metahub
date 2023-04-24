// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@solidstate/contracts/interfaces/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./UpgradableOwnable.sol";
import "../../interfaces/ITxnHubSimpleNFT.sol";

contract TxnSimpleMarket is UpgradableOwnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

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

    //end initialize

    //common function
    function _divRound(uint x, uint y) pure internal returns (uint)  {
        return (x + (y / 2)) / y;
    }

    //start exchange rate

    AggregatorV3Interface internal priceFeed;//USD/USDT 到 数字货币的汇率源
    bool internal priceInverse;//汇率是否需要反向，true: usd_price/rate; false: usd_price * rate
    uint8 private _chainBalanceDigits;

    function _modifyChainBalanceDigits(uint8 digits) internal {
        _chainBalanceDigits = digits;
    }

    function modifyChainBalanceDigits(uint8 digits) external onlyOwner {
        _modifyChainBalanceDigits(digits);
    }

    function _chainDigits() internal virtual view returns (uint8){
        return _chainBalanceDigits;
    }

    function _updatePriceFeed(address priceFeedAddr, bool inverseFlag) internal virtual {
        priceFeed = AggregatorV3Interface(priceFeedAddr);
        priceInverse = inverseFlag;
    }

    function updatePriceFeed(address priceFeedAddr, bool inverseFlag) external onlyOwner {
        _updatePriceFeed(priceFeedAddr, inverseFlag);
    }

    function currentExchangeRate() public view returns (uint256 rate, uint8 decimals) {
        uint8 decimal = priceFeed.decimals();
        (, int256 price, , ,) = priceFeed.latestRoundData();
        uint256 _rate = uint256(price);
        if (priceInverse) {
            _rate = (10 ** (decimal * 2)) / _rate;
        }
        uint256 _floatedRate = _divRound(_rate * (10000 + floatingRate_), 10000);
        return (_floatedRate, decimal);
    }
    //end exchange rate

    //start mintable goods

    struct GoodsInfo {
        uint32 price;//售价(USD/USDT)
        bool onSale;//是否上架、下架
        ITxnHubSimpleNFT nftContract;//nft合约地址
    }

    mapping(uint128 => GoodsInfo) private _goods;

    event GoodsOnSaleEvent(uint128 indexed goodsId, bool onSale);

    function addGoods(uint128 goodsId, address nftContract, uint32 price) external onlyOperator {
        require(price > 0, "Market: price must have value");
        require(nftContract != address(0), "Market: invalid contract address");
        require(ITxnHubSimpleNFT(nftContract).isTxnHubSimpleContract(), "Market: not txn hub contract");
        _goods[goodsId] = GoodsInfo(price, true, ITxnHubSimpleNFT(nftContract));
        emit GoodsOnSaleEvent(goodsId, true);
    }

    function goodsInfo(uint128 goodsId_) external onlyOperator view returns (GoodsInfo memory goods) {
        require(_goods[goodsId_].price > 0, "Market: Goods price not configured");
        return _goods[goodsId_];
    }

    function setOnSale(uint128 goodsId_, bool onSale_) external onlyOperator {
        require(_goods[goodsId_].price > 0, "Market: Goods price not configured");
        require(_goods[goodsId_].onSale != onSale_, "Market: no need to edit");
        _goods[goodsId_].onSale = onSale_;
        emit GoodsOnSaleEvent(goodsId_, onSale_);
    }

    event MintGoodsEvent(uint128 indexed goodsId,
        address nftContract,
        address mintTo,
        uint128 amount,
        uint128 usdPrice,
        uint256 paidFee,
        uint256 rate
    );


    function _mintNft(address operator, uint128 goodsId_, uint128 amount, address to, uint256 paid, uint256 rate) internal {
        require(_goods[goodsId_].onSale, "Market: Goods not on sale");
        GoodsInfo memory info = _goods[goodsId_];
        info.nftContract.agentMintId(operator, to, goodsId_, amount, "0x0");
        emit MintGoodsEvent(goodsId_,
            address(info.nftContract),
            to,
            amount,
            _goods[goodsId_].price,
            paid,
            rate
        );
    }

    function _calculateChainPrice(uint128 goodsId_, uint128 amount) internal view returns (uint256 total, uint256 rate){
        uint128 goodsPrice = _goods[goodsId_].price;
        (uint _rate, uint decimals) = currentExchangeRate();
        uint256 chainPrice = _divRound(goodsPrice * _rate * (10 ** _chainDigits()), (10 ** (decimals + 2)));
        uint256 totalPrice = chainPrice * amount;
        return (totalPrice, _rate);
    }

    function mintPriceEstimate(uint128 goodsId_, uint128 amount) external view returns (uint256 total) {
        (uint256 totalFee,) = _calculateChainPrice(goodsId_, amount);
        return totalFee;
    }

    function ownerMint(uint128 goodsId_, uint128 amount, address to) external onlyOperator {
        (uint256 rate,) = currentExchangeRate();
        return _mintNft(_msgSender(), goodsId_, amount, to, 0, rate);
    }

    function customerMint(uint128 goodsId_, uint128 amount) external payable {
        (uint256 totalPrice, uint256 rate) = _calculateChainPrice(goodsId_, amount);
        require(msg.value >= totalPrice, "Market: price not match");
        _mintNft(_msgSender(), goodsId_, amount, _msgSender(), msg.value, rate);
    }

    //end mintable goods

    //start burn

    struct NftBurnRecord {
        address contractAddress;
        address owner;
        uint128 tokenId;
    }

    event NftBurnEvent(uint256 indexed burnId, string email);

    mapping(uint256 => NftBurnRecord) private _burnRecords;

    Counters.Counter private _burnId;

    function burnRecord(uint256 burnId_) external onlyOperator view returns (NftBurnRecord memory){
        require(burnId_ <= _burnId.current(), "Market: Invalid burn id");
        return _burnRecords[burnId_];
    }

    function burn(address contractAddress, uint128 tokenId, string calldata email) external {
        ITxnHubSimpleNFT(contractAddress).agentBurn(_msgSender(), tokenId, 1);
        _burnId.increment();
        uint256 currentBurnId = _burnId.current();
        _burnRecords[currentBurnId] = NftBurnRecord(contractAddress, _msgSender(), tokenId);
        emit NftBurnEvent(currentBurnId, email);
    }
    //end burn
    //start nft market

    struct SellList {
        bool onSale;
        uint64 price;
    }

    event SaleChangeEvent (
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
        uint256 _totalPrice,
        uint256 _rate);

    mapping(address => mapping(address => mapping(uint128 => SellList))) private _saleMapping;

    function querySaleStatus(address seller_, address nftContractAddr_, uint128 tokenId_) external view returns (
        uint128 balance,
        uint64 price
    ){
        SellList memory sale = _saleMapping[seller_][nftContractAddr_][tokenId_];
        require(sale.onSale, "Market: not on sale");
        uint128 _balance = uint128(IERC1155(nftContractAddr_).balanceOf(seller_, tokenId_));
        require(_balance > 0, "Market: balance not enough");
        return (_balance, sale.price);
    }

    function onSale(address nftContract_,
        uint128 tokenId_,
        uint64 price_
    ) external {
        require(price_ > 0, "Market: Price must more than 0");
        require(ITxnHubSimpleNFT(nftContract_).isTxnHubSimpleContract(), "ITxnHubSimpleNFT: not Txn Hub NFT");
        require(IERC1155(nftContract_).balanceOf(_msgSender(), tokenId_) > 0, "ITxnHubSimpleNFT: NFT balance is 0");
        _saleMapping[msg.sender][nftContract_][tokenId_] = SellList(
            true,
            price_);
        emit SaleChangeEvent(msg.sender, nftContract_, tokenId_, true);
    }

    function cancelSale(address nftContractAddr_, uint128 tokenId_) external {
        require(_saleMapping[msg.sender][nftContractAddr_][tokenId_].onSale, "Market: Already canceled");
        _saleMapping[msg.sender][nftContractAddr_][tokenId_].onSale = false;
        emit SaleChangeEvent(msg.sender, nftContractAddr_, tokenId_, false);
    }

    function _buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) internal view returns (uint256 total, uint256 rate) {
        require(_saleMapping[seller_][nftContractAddr_][tokenId_].onSale, "Market: Not on sale");
        (uint256 rate_,uint8 decimals) = currentExchangeRate();
        uint256 singlePrice = _divRound(_saleMapping[seller_][nftContractAddr_][tokenId_].price * rate * (10 ** _chainDigits()), 10 ** (decimals + 2));
        uint256 totalPrice = singlePrice * amount_;
        return (totalPrice, rate_);
    }

    function buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) public view returns (uint256 total) {
        (uint256 totalPrice, ) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_);
        return totalPrice;
    }

    /**
      @param seller_ This is the seller address
      @param nftContractAddr_ This is nft contract address
      @param tokenId_ This is nft token id
      @param amount_ This is buy amount of selling tokens
    **/
    function buyToken(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) external payable {
        (uint256 totalPrice, uint256 rate) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_);
        require(msg.sender != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        require(msg.value >= totalPrice, "Market: Paid amount needs to be greater or equals total price.");

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
            msg.value,
            rate);

        // transfer totalPaid-totalFee to seller's wallet
        // todo gas fee may not enough
        bool sent = seller_.send(msg.value);
        require(sent, "Market: send value failed");

    }
    //add market floating rate - 2023-02-13
    //汇率浮动
    uint16 private floatingRate_;

    function updateFloatingRate(uint16 newFloatingRate) external onlyOperator {
        floatingRate_ = newFloatingRate;
    }

    function currentFloatingRate() external view onlyOperator returns (uint16){
        return floatingRate_;
    }
}
