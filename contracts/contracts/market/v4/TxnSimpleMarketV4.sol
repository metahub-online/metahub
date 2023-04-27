// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/interfaces/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../interfaces/ITxnHubSimpleNFT.sol";
import "../../interfaces/IMintableMarket.sol";
import "../../interfaces/IMarketRoleManager.sol";
import "../../interfaces/INftSaleMarket.sol";
import "../v1/TxnMarketPermissionSupportV1.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TxnSimpleMarketV4 is TxnMarketPermissionSupportV1 {


    //start exchange rate

    AggregatorV3Interface internal priceFeed;//USD/USDT 到 数字货币的汇率源
    bool internal priceInverse;//汇率是否需要反向，true: usd_price/rate; false: usd_price * rate
    uint8 private _chainBalanceDigits;
    //add market floating rate - 2023-02-13
    //汇率浮动
    uint16 private floatingRate_;

    function updateFloatingRate(uint16 newFloatingRate) external onlyOperator {
        floatingRate_ = newFloatingRate;
    }

    function currentFloatingRate() external view onlyOperator returns (uint16){
        return floatingRate_;
    }

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
        (uint256 _floatRate, uint8 decimal, ,) = currentExchangeRateOfRound(uint80(0));
        return (_floatRate, decimal);
    }

    function currentExchangeRateOfRound(uint80 roundId_) public view returns (uint256 rate, uint8 decimals, uint80 roundId, uint256 startAt) {
        uint8 decimal = priceFeed.decimals();
        (uint80 resRoundId,int256 price,uint256 startAt_, ,) = roundId_ > 0 ? priceFeed.getRoundData(roundId_) : priceFeed.latestRoundData();
        uint256 _rate = uint256(price);
        if (priceInverse) {
            _rate = (10 ** (decimal * 2)) / _rate;
        }
        uint256 _floatedRate = _divRound(_rate * (10000 + floatingRate_), 10000);
        return (_floatedRate, decimal, resRoundId, startAt_);
    }
    //end exchange rate

    //storage contracts

    IMintableMarket private _mintableMarket;
    INftSaleMarket private _nftSaleMarket;

    function updateMintableMarket(address contractAddr) external onlyOwner {
        _mintableMarket = IMintableMarket(contractAddr);
    }

    function updateNftSaleMarket(address contractAddr) external onlyOwner {
        _nftSaleMarket = INftSaleMarket(contractAddr);
    }

    function addGoods(uint128 goodsId, address nftContract, uint32 price) external onlyOperator {
        _mintableMarket.addGoods(goodsId, nftContract, price);
    }

    function batchAddGoods(address nftContract, uint128[] calldata goodsIds, uint32[] calldata prices) external onlyOperator {
        uint goodsCount = goodsIds.length;
        require(goodsCount == prices.length, "Market: id and price count not match");
        for (uint i = 0; i < goodsCount; i++) {
            _mintableMarket.addGoods(goodsIds[i], nftContract, prices[i]);
        }
    }

    function goodsInfo(uint128 goodsId_) external onlyOperator view returns (IMintableMarket.GoodsInfo memory goods) {
        return _mintableMarket.goodsInfo(goodsId_);
    }

    function setOnSale(uint128 goodsId_, bool onSale_) external onlyOperator {
        _mintableMarket.goodsOnSale(goodsId_, onSale_);
    }

    function _calculateChainPrice(uint128 goodsId_, uint128 amount, uint16 stableId, uint80 roundId_) internal view returns (uint256 total, uint256 rate, uint80 roundId){
        IMintableMarket.GoodsInfo memory goods = _mintableMarket.goodsInfo(goodsId_);
        uint128 goodsPrice = goods.price;
        (uint _rate, uint decimals, uint80 rateRoundId, uint256 startAt) = currentStableExchangeRate(stableId, roundId_);
        uint256 curTime = block.timestamp;
        require(startAt + _rateTimeOffsetSeconds > curTime, "Exchange rate expired");
        uint8 digits = stableId != uint16(0) ? stablePriceDecimals[stableId] : _chainDigits();
        uint256 chainPrice = _divRound(goodsPrice * _rate * (10 ** digits), (10 ** (decimals + 2)));
        uint256 totalPrice = chainPrice * amount;
        return (totalPrice, _rate, rateRoundId);
    }

    function mintPriceEstimate(uint128 goodsId_, uint128 amount) external view returns (uint256 total, uint80 roundId) {
        (uint256 totalFee, ,uint80 rateRoundId) = _calculateChainPrice(goodsId_, amount, uint16(0), uint80(0));
        return (totalFee, rateRoundId);
    }

    function mintPriceStableEstimate(uint128 goodsId_, uint128 amount, uint16 stableId) external view returns (uint256 total, uint80 roundId) {
        (uint256 totalFee, ,uint80 rateRoundId) = _calculateChainPrice(goodsId_, amount, stableId, uint80(0));
        return (totalFee, rateRoundId);
    }

    function ownerMint(uint128 goodsId_, uint128 amount, address to) external onlyOperator {
        (uint256 rate,) = currentExchangeRate();
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, to, 0, rate);
    }

    function customerMint(uint128 goodsId_, uint128 amount) external payable {
        (uint256 totalPrice, uint256 rate,) = _calculateChainPrice(goodsId_, amount, uint16(0), uint80(0));
        require(msg.value >= totalPrice, "Market: price not match");
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), msg.value, rate);
    }

    function customerMintInRound(uint128 goodsId_, uint128 amount, uint80 roundId_) external payable {
        (uint256 totalPrice, uint256 rate,) = _calculateChainPrice(goodsId_, amount, uint16(0), roundId_);
        require(msg.value >= totalPrice, "Market: price not match");
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), msg.value, rate);
    }

    function customerMintStable(uint128 goodsId_, uint128 amount, uint16 stableId) external {
        require(stableId > 0, 'Currency not determined');
        address erc20ContractAddr = stableContracts[stableId];
        require(erc20ContractAddr != address(0), 'Not configured currency');
        IERC20 erc20Contract = IERC20(erc20ContractAddr);

        (uint256 totalPrice, uint256 rate,) = _calculateChainPrice(goodsId_, amount, stableId, uint80(0));

        uint256 allowance_amt = erc20Contract.allowance(_msgSender(), address(this));
        require(allowance_amt >= totalPrice, "Allowance balance insufficient");

        address asset = currentAsset();
        bool success = erc20Contract.transferFrom(_msgSender(), asset, totalPrice);
        require(success, "ERC20 Deduction failed");

        uint256 evtPrice = uint256(stableId) << 240;
        evtPrice = evtPrice | totalPrice;
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), evtPrice, rate);
    }

    function customerMintStableInRound(uint128 goodsId_, uint128 amount, uint16 stableId, uint80 roundId_) external {
        require(stableId > 0, 'Currency not determined');
        address erc20ContractAddr = stableContracts[stableId];
        require(erc20ContractAddr != address(0), 'Not configured currency');
        IERC20 erc20Contract = IERC20(erc20ContractAddr);

        (uint256 totalPrice, uint256 rate,) = _calculateChainPrice(goodsId_, amount, stableId, roundId_);

        uint256 allowance_amt = erc20Contract.allowance(_msgSender(), address(this));
        require(allowance_amt >= totalPrice, "Allowance balance insufficient");

        address asset = currentAsset();
        bool success = erc20Contract.transferFrom(_msgSender(), asset, totalPrice);
        require(success, "ERC20 Deduction failed");

        uint256 evtPrice = uint256(stableId) << 240;
        evtPrice = evtPrice | totalPrice;
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), evtPrice, rate);
    }

    //end mintable goods

    //start burn

    function burnRecord(uint256 burnId_) external onlyOperator view returns (IMintableMarket.NftBurnRecord memory){
        return _mintableMarket.burnRecord(burnId_);
    }

    function burn(address contractAddress, uint128 tokenId, string calldata email) external {
        _mintableMarket.burn(_msgSender(), contractAddress, tokenId, 1, email);
    }
    //end burn
    //start nft market
    event TradeEvent(
        address indexed _nftContract,
        address indexed _seller,
        address _buyer,
        uint128 indexed _tokenId,
        uint32 _amount,
        uint256 _totalPrice,
        uint256 _rate);

    function querySaleStatus(address seller_, address nftContractAddr_, uint128 tokenId_) external view returns (
        uint128 balance,
        uint64 price
    ){
        return _nftSaleMarket.querySaleStatus(seller_, nftContractAddr_, tokenId_);
    }

    function onSale(address nftContract_,
        uint128 tokenId_,
        uint64 price_
    ) external {
        _nftSaleMarket.onSale(_msgSender(), nftContract_, tokenId_, price_);
    }

    function cancelSale(address nftContractAddr_, uint128 tokenId_) external {
        _nftSaleMarket.cancelSale(_msgSender(), nftContractAddr_, tokenId_);
    }

    function _buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint16 stableId_, uint80 roundId_) internal view returns (uint256 total, uint256 rate, uint80 roundId) {
        (, uint64 price) = _nftSaleMarket.querySaleStatus(seller_, nftContractAddr_, tokenId_);
        (uint256 rate_,uint8 decimals, uint80 rateRoundId, uint256 startAt) = currentStableExchangeRate(stableId_, roundId_);
        uint256 curTime = block.timestamp;
        require(startAt + _rateTimeOffsetSeconds > curTime, "Rate expired");
        uint8 digits = stableId_ != uint16(0) ? stablePriceDecimals[stableId_] : _chainDigits();
        uint256 singlePrice = _divRound(price * rate_ * (10 ** digits), 10 ** (decimals + 2));
        uint256 totalPrice = singlePrice * amount_;
        return (totalPrice, rate_, rateRoundId);
    }

    function buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) public view returns (uint256 total, uint80 roundId) {
        (uint256 totalPrice,,uint80 rateRoundId) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, uint16(0), uint80(0));
        return (totalPrice, rateRoundId);
    }

    function buyTokenWithStableEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint16 stableId_) public view returns (uint256 total, uint80 roundId) {
        (uint256 totalPrice,,uint80 rateRoundId) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, stableId_, uint80(0));
        return (totalPrice, rateRoundId);
    }

    /**
      @param seller_ This is the seller address
      @param nftContractAddr_ This is nft contract address
      @param tokenId_ This is nft token id
      @param amount_ This is buy amount of selling tokens
    **/
    function buyToken(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) external payable {
        (uint256 totalPrice, uint256 rate,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, uint16(0), uint80(0));
        require(_msgSender() != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        require(msg.value >= totalPrice, "Market: Paid amount needs to be greater or equals total price.");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            _msgSender(),
            tokenId_,
            amount_,
            "0x0");

        emit TradeEvent(nftContractAddr_,
            seller_,
            _msgSender(),
            tokenId_,
            amount_,
            msg.value,
            rate);

        bool sent = seller_.send(msg.value);
        require(sent, "Market: send value failed");

    }

    /**
      @param seller_ This is the seller address
      @param nftContractAddr_ This is nft contract address
      @param tokenId_ This is nft token id
      @param amount_ This is buy amount of selling tokens
      @param roundId_ Rate round id to use history rate to prevent insufficient funds
    **/
    function buyTokenInRound(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint80 roundId_) external payable {
        (uint256 totalPrice, uint256 rate,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, uint16(0), roundId_);
        require(_msgSender() != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        require(msg.value >= totalPrice, "Market: Paid amount needs to be greater or equals total price.");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            _msgSender(),
            tokenId_,
            amount_,
            "0x0");

        emit TradeEvent(nftContractAddr_,
            seller_,
            _msgSender(),
            tokenId_,
            amount_,
            msg.value,
            rate);

        bool sent = seller_.send(msg.value);
        require(sent, "Market: send value failed");

    }

    function buyTokenStable(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint16 stableId_) external {
        require(stableId_ > 0, "Currency not detected");
        address erc20Addr = stableContracts[stableId_];
        require(erc20Addr != address(0), "Currency not configured");

        (uint256 totalPrice, uint256 rate,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, stableId_, uint80(0));
        require(_msgSender() != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        IERC20 erc20Contract = IERC20(erc20Addr);
        uint256 allowance_amt = erc20Contract.allowance(_msgSender(), address(this));
        require(allowance_amt >= totalPrice, "Market: Allowance insufficient");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            _msgSender(),
            tokenId_,
            amount_,
            "0x0");

        bool sent = erc20Contract.transferFrom(_msgSender(), seller_, totalPrice);
        require(sent, "Market: transfer erc20 failed");

        uint256 evtAmount = uint256(stableId_) << 240;
        evtAmount = evtAmount | totalPrice;

        emit TradeEvent(nftContractAddr_,
            seller_,
            _msgSender(),
            tokenId_,
            amount_,
            evtAmount,
            rate);

    }

    function buyTokenStableInRound(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint16 stableId_, uint80 roundId_) external {
        require(stableId_ > 0, "Currency not detected");
        address erc20Addr = stableContracts[stableId_];
        require(erc20Addr != address(0), "Currency not configured");

        (uint256 totalPrice, uint256 rate,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, stableId_, roundId_);
        require(_msgSender() != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        IERC20 erc20Contract = IERC20(erc20Addr);
        uint256 allowance_amt = erc20Contract.allowance(_msgSender(), address(this));
        require(allowance_amt >= totalPrice, "Market: Allowance insufficient");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            _msgSender(),
            tokenId_,
            amount_,
            "0x0");

        bool sent = erc20Contract.transferFrom(_msgSender(), seller_, totalPrice);
        require(sent, "Market: transfer erc20 failed");

        uint256 evtAmount = uint256(stableId_) << 240;
        evtAmount = evtAmount | totalPrice;

        emit TradeEvent(nftContractAddr_,
            seller_,
            _msgSender(),
            tokenId_,
            amount_,
            evtAmount,
            rate);

    }

    function contractBalance() public view onlyOperator returns (uint256 balance) {
        return address(this).balance;
    }

    function withdrawAll() external onlyOperator {
        uint256 balance = contractBalance();
        require(balance > 0, "not enough balance");
        address assetAccount = currentAsset();
        require(assetAccount != address(0), "invalid asset account");
        bool sent = payable(assetAccount).send(balance);
        require(sent, "Withdraw: withdraw failed");
    }

    //2023-04-17 add usdt and other stable currency support
    mapping(uint16 => address) internal stableContracts;
    mapping(uint16 => address) internal stablePriceFeeds;
    mapping(uint16 => bool) internal stablePriceInverses;
    mapping(uint16 => uint8) internal stablePriceDecimals;

    event StableCurrencyToggle(uint16 indexed stableId,
        bool indexed activeFlag,
        bool priceFeedInverse,
        address indexed erc20Contract,
        address priceFeed);

    function _configStableCurrency(uint16 stableId, uint8 decimals, address priceFeedAddr, bool inverseFlag, address contractAddr) internal virtual {
        require(contractAddr != address(0), "Already configured stableId");
        AggregatorV3Interface stablePriceFeed = AggregatorV3Interface(priceFeedAddr);
        uint8 decimal = stablePriceFeed.decimals();
        require(decimal > 0, "Price Feed addr not valid");
        IERC20 erc20Contract = IERC20(contractAddr);
        uint256 supply = erc20Contract.totalSupply();
        require(supply > 0, "Invalid erc20 contract");
        stableContracts[stableId] = contractAddr;
        stablePriceFeeds[stableId] = priceFeedAddr;
        stablePriceInverses[stableId] = inverseFlag;
        stablePriceDecimals[stableId] = decimals;
        emit StableCurrencyToggle(stableId, true, inverseFlag, contractAddr, priceFeedAddr);
    }

    function configStableCurrency(uint16 stableId, uint8 decimals, address priceFeedAddr, bool inverseFlag, address contractAddr) external onlyOperator {
        _configStableCurrency(stableId, decimals, priceFeedAddr, inverseFlag, contractAddr);
    }

    function disableStableCurrency(uint16 stableId) external onlyOperator {
        address contractAddr = stableContracts[stableId];
        require(contractAddr != address(0), "Already disabled");
        address priceFeedAddr = stablePriceFeeds[stableId];
        bool priceFeedInverse = stablePriceInverses[stableId];
        stableContracts[stableId] = address(0);
        emit StableCurrencyToggle(stableId, false, priceFeedInverse, contractAddr, priceFeedAddr);
    }

    function stableCurrencyInfo(uint16 stableId) external view returns (address erc20Contract, address priceFeedContract, bool inverse) {
        return (stableContracts[stableId], stablePriceFeeds[stableId], stablePriceInverses[stableId]);
    }

    function currentStableExchangeRate(uint16 stableId, uint80 roundId_) public view returns (uint256 rate, uint8 decimals, uint80 roundId, uint256 startAt) {
        if (stableId == uint16(0)) {
            return currentExchangeRateOfRound(roundId_);
        }
        address feedAddr = stablePriceFeeds[stableId];
        require(feedAddr != address(0), 'Not configured stable currency price feed');
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddr);
        uint8 decimal = feed.decimals();
        (uint80 resRoundId, int256 price, uint256 startAt_, ,) = roundId_ > 0 ? feed.getRoundData(roundId_) : feed.latestRoundData();
        uint256 _rate = uint256(price);
        if (stablePriceInverses[stableId]) {
            _rate = (10 ** (decimal * 2)) / _rate;
        }
        uint256 _floatedRate = _divRound(_rate * (10000 + floatingRate_), 10000);
        return (_floatedRate, decimal, resRoundId, startAt_);
    }

    //2023-04-22 rate valid time
    uint8 internal _rateTimeOffset;
    uint16 internal _rateTimeOffsetSeconds;

    function currentRateTimeOffset() external view returns (uint16) {
        return _rateTimeOffsetSeconds;
    }

    function configRateTimeOffset(uint16 second_count) external onlyOperator {
        _rateTimeOffsetSeconds = second_count;
    }

    //init
    function initialize(address roleManagerContract, address mintableMarketContract, address nftSaleMarketContract,
        address priceFeedAddress, bool priceInverse_, uint8 chainDigits_, uint8 rateTimeOffset_) external initializer {
        _transferOwnership(_msgSender());
        _updatePriceFeed(priceFeedAddress, priceInverse_);
        _modifyChainBalanceDigits(chainDigits_);
        updateRoleManager(roleManagerContract);
        _mintableMarket = IMintableMarket(mintableMarketContract);
        _nftSaleMarket = INftSaleMarket(nftSaleMarketContract);
        _rateTimeOffsetSeconds = rateTimeOffset_;
    }
}
