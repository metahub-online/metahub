// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../interfaces/ITxnHubNFT.sol";
import "./TxnPartnerShipSupport.sol";

contract TxnMintableMarket is TxnPartnerShipSupport {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    AggregatorV3Interface internal priceFeed;//USD/USDT 到 数字货币的汇率源
    bool internal priceInverse;//汇率是否需要反向，true: usd_price/rate; false: usd_price * rate

    struct GoodsInfo {
        uint32 price;//面值(USD/USDT)
        uint16 platformDiscount;//平台折扣(1=万分之一)
        bool onSale;//是否上架、下架
        ITxnHubNFT nftContract;//nft合约地址
    }


    mapping(uint128 => GoodsInfo) private _goods;

    event GoodsOnSaleEvent(uint128 indexed goodsId, bool onSale);


    struct TokenIdReference {
        address partner;
        uint128 goodsId;
    }

    mapping(address => mapping(uint256 => TokenIdReference)) _nftTokenIdReference;

    event MintGoodsEvent(uint128 indexed goodsId,
        uint128 indexed tokenId,
        address nftContract,
        address agent,
        uint128 amount,
        uint128 usdPrice,
        uint256 paidFee
    );


    struct NftBurnRecord {
        address contractAddress;
        address owner;
        uint128 tokenId;
        uint128 goodsId;
        address partner;
    }

    event NftBurnEvent(uint256 indexed burnId, string email);

    mapping(uint256 => NftBurnRecord) private _burnRecords;
    Counters.Counter private _burnId;

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


    function addGoods(uint128 goodsId, address nftContract, uint32 price, uint16 platformDiscount) external onlyOperator {
        require(price > 0, "Market: price must have value");
        require(platformDiscount <= 10000, "Market: invalid discount");
        require(nftContract != address(0), "Market: invalid contract address");
        require(ITxnHubNFT(nftContract).isTxnHubContract(), "Market: not txn hub contract");
        _goods[goodsId] = GoodsInfo(price, platformDiscount, true, ITxnHubNFT(nftContract));
        emit GoodsOnSaleEvent(goodsId, true);
    }

    function modifyGoods(uint128 goodsId_, uint32 price, uint16 platformDiscount) external onlyOperator {
        require(price > 0, "Market: price must have value");
        require(platformDiscount <= 10000, "Market: invalid discount");
        require(address(_goods[goodsId_].nftContract) != address(0), "Market: Goods contract not configured");
        _goods[goodsId_].price = price;
        _goods[goodsId_].platformDiscount = platformDiscount;
    }

    function goodsInfo(uint128 goodsId_) external onlyOperator view returns (GoodsInfo memory goods) {
        require(_goods[goodsId_].price > 0, "Market: Goods price not configured");
        return _goods[goodsId_];
    }

    function setOnSale(uint128 goodsId_, bool onSale) external onlyOperator {
        require(_goods[goodsId_].price > 0, "Market: Goods price not configured");
        require(_goods[goodsId_].onSale != onSale, "Market: no need to edit");
        _goods[goodsId_].onSale = onSale;
        emit GoodsOnSaleEvent(goodsId_, onSale);
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
        return (_rate, decimal);
    }

    function _mintNft(address operator, uint128 goodsId_, uint128 amount, address to, uint128 goodsPrice, uint256 paid) internal {
        require(_goods[goodsId_].onSale, "Market: Goods not on sale");
        GoodsInfo memory info = _goods[goodsId_];
        require(_getPartner(to).enable, "Market: target is not valid partner");
        uint128 tokenId = uint128(info.nftContract.agentMint(operator, to, amount, "0x0"));
        _nftTokenIdReference[address(info.nftContract)][tokenId] = TokenIdReference(to, goodsId_);
        emit MintGoodsEvent(goodsId_,
            tokenId,
            address(info.nftContract),
            to,
            amount,
            goodsPrice,
            paid
        );
    }

    function ownerMint(uint128 goodsId_, uint128 amount, address to) external onlyOperator {
        uint128 goodsPrice = _calculateAgentGoodsUsdPrice(goodsId_, to);
        return _mintNft(_msgSender(), goodsId_, amount, to, goodsPrice, 0);
    }

    function agentPriceEstimate(uint128 goodsId_, uint128 amount) external view onlyPartner returns (uint256 total, uint128 usdPrice) {
        return _calculateAgentPrice(goodsId_, amount, _msgSender());
    }

    function _calculateAgentGoodsUsdPrice(uint128 goodsId_, address to) internal view returns (uint128){
        require(_goods[goodsId_].onSale, "Market: Goods not on sale");
        GoodsInfo memory info = _goods[goodsId_];
        PartnerShip memory partner = _getPartner(to);
        require(partner.enable, "Market: not valid partner");
        uint8 partnerDiscount = 0;
        if (partner.level > 0) {
            partnerDiscount = 4 + partner.level;
        }
        if (partnerDiscount > 10) {
            partnerDiscount = 10;
        }
        uint16 discount = info.platformDiscount * partnerDiscount / 10;
        return uint128(_divRound(info.price * (10000 - discount), 10000));
    }

    function _calculateAgentPrice(uint128 goodsId_, uint128 amount, address to) internal view returns (uint256 agentPrice, uint128 _goodsPrice){
        uint128 goodsPrice = _calculateAgentGoodsUsdPrice(goodsId_, to);
        (uint rate, uint decimals) = currentExchangeRate();
        uint256 partnerPrice = _divRound(goodsPrice * rate * (10 ** _chainDigits()), (10 ** (decimals + 2)));
        uint256 totalPrice = partnerPrice * amount;
        return (totalPrice, goodsPrice);
    }

    function agentMint(uint128 goodsId_, uint128 amount) external payable onlyPartner {
        (uint256 totalPrice, uint128 goodsPrice) = _calculateAgentPrice(goodsId_, amount, _msgSender());
        require(msg.value >= totalPrice, "Market: price not match");
        _mintNft(_msgSender(), goodsId_, amount, _msgSender(), goodsPrice, msg.value);
    }

    function burnRecord(uint256 burnId_) external onlyObserver view returns (NftBurnRecord memory){
        require(burnId_ <= _burnId.current(), "Market: Invalid burn id");
        return _burnRecords[burnId_];
    }

    function burn(address contractAddress, uint128 tokenId, string calldata email) external {
        TokenIdReference memory refer = _nftTokenIdReference[contractAddress][tokenId];
        require(refer.partner != address(0), "Market: Invalid NFT token");
        ITxnHubNFT(contractAddress).agentBurnSingle(_msgSender(), tokenId);
        _burnId.increment();
        uint256 currentBurnId = _burnId.current();
        _burnRecords[currentBurnId] = NftBurnRecord(contractAddress, _msgSender(), tokenId, refer.goodsId, refer.partner);
        emit NftBurnEvent(currentBurnId, email);
    }

    function _shareNftTradeFee(address contractAddress, uint128 tokenId, uint256 fee) internal {
        TokenIdReference memory refer = _nftTokenIdReference[contractAddress][tokenId];
        if (refer.partner != address(0) && fee > 0) {
            _shareRecipient(refer.partner, fee);
        }
    }

    function _divRound(uint x, uint y) pure internal returns (uint)  {
        return (x + (y / 2)) / y;
    }
}
