// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/interfaces/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../interfaces/ITxnHubSimpleNFT.sol";
import "../../interfaces/IMintableMarket.sol";
import "../../interfaces/IMarketRoleManager.sol";
import "../../interfaces/INftSaleMarket.sol";
import "./TxnMarketPermissionSupportV1.sol";

contract TxnSimpleMarketV1 is TxnMarketPermissionSupportV1 {


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

    function goodsInfo(uint128 goodsId_) external onlyOperator view returns (IMintableMarket.GoodsInfo memory goods) {
        return _mintableMarket.goodsInfo(goodsId_);
    }

    function setOnSale(uint128 goodsId_, bool onSale_) external onlyOperator {
        _mintableMarket.goodsOnSale(goodsId_, onSale_);
    }

    function _calculateChainPrice(uint128 goodsId_, uint128 amount) internal view returns (uint256 total, uint256 rate){
        IMintableMarket.GoodsInfo memory goods = _mintableMarket.goodsInfo(goodsId_);
        uint128 goodsPrice = goods.price;
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
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, to, 0, rate);
    }

    function customerMint(uint128 goodsId_, uint128 amount) external payable {
        (uint256 totalPrice, uint256 rate) = _calculateChainPrice(goodsId_, amount);
        require(msg.value >= totalPrice, "Market: price not match");
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), msg.value, rate);
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

    function _buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) internal view returns (uint256 total, uint256 rate) {
        (, uint64 price) = _nftSaleMarket.querySaleStatus(seller_, nftContractAddr_, tokenId_);
        (uint256 rate_,uint8 decimals) = currentExchangeRate();
        uint256 singlePrice = _divRound(price * rate * (10 ** _chainDigits()), 10 ** (decimals + 2));
        uint256 totalPrice = singlePrice * amount_;
        return (totalPrice, rate_);
    }

    function buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) public view returns (uint256 total) {
        (uint256 totalPrice,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_);
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

        // transfer totalPaid-totalFee to seller's wallet
        // todo gas fee may not enough
        bool sent = seller_.send(msg.value);
        require(sent, "Market: send value failed");

    }

    function contractBalance() public view onlyOperator returns (uint256 balance) {
        return address(this).balance;
    }

    function withdrawAll() external onlyOperator {
        uint256 balance = contractBalance();
        require(balance > 0, "not enough balance");
        address assetAccount = currentAsset();
        require(assetAccount!=address (0),"invalid asset account");
        bool sent = payable(assetAccount).send(balance);
        require(sent, "Withdraw: withdraw failed");
    }

    //init
    function initialize(address roleManagerContract, address mintableMarketContract, address nftSaleMarketContract,
        address priceFeedAddress, bool priceInverse_, uint8 chainDigits_) external initializer {
        _transferOwnership(_msgSender());
        _updatePriceFeed(priceFeedAddress, priceInverse_);
        _modifyChainBalanceDigits(chainDigits_);
        updateRoleManager(roleManagerContract);
        _mintableMarket = IMintableMarket(mintableMarketContract);
        _nftSaleMarket = INftSaleMarket(nftSaleMarketContract);
    }
}
