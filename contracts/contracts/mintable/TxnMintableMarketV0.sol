// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMintableMarket.sol";
import "../support/TxnMarketStorageBase.sol";


contract TxnMintableMarketV0 is TxnMarketStorageBase, IMintableMarket {
    using Counters for Counters.Counter;

    mapping(uint128 => GoodsInfo) private _goods;

    Counters.Counter private _burnId;
    mapping(uint256 => NftBurnRecord) private _burnRecords;

    function initialize() public initializer {
        _transferOwnership(_msgSender());
    }

    function addGoods(uint128 goodsId, address nftContract, uint32 price) external override onlyAuthContract {
        require(price > 0, "Market: price must have value");
        require(nftContract != address(0), "Market: invalid contract address");
        require(ITxnHubSimpleNFT(nftContract).isTxnHubSimpleContract(), "Market: not txn hub contract");
        _goods[goodsId] = GoodsInfo(price, true, ITxnHubSimpleNFT(nftContract));
        emit GoodsOnSaleEvent(goodsId, true);
    }

    function goodsInfo(uint128 goodsId_) external override view onlyAuthContract returns (GoodsInfo memory goods) {
        require(_goods[goodsId_].price > 0, "Market: Goods price not configured");
        return _goods[goodsId_];
    }

    function goodsOnSale(uint128 goodsId_, bool onSale_) external override onlyAuthContract {
        require(_goods[goodsId_].price > 0, "Market: Goods price not configured");
        require(_goods[goodsId_].onSale != onSale_, "Market: no need to edit");
        _goods[goodsId_].onSale = onSale_;
        emit GoodsOnSaleEvent(goodsId_, onSale_);
    }

    function mintNft(address operator, uint128 goodsId_, uint128 amount, address to, uint256 paid, uint256 rate) external override onlyAuthContract {
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

    function burnRecord(uint256 burnId_) external view override returns (NftBurnRecord memory){
        require(burnId_ <= _burnId.current(), "Market: Invalid burn id");
        return _burnRecords[burnId_];
    }

    function burn(address operator, address contractAddress, uint128 tokenId, uint256 quantity, string calldata email) external override onlyAuthContract {
        ITxnHubSimpleNFT(contractAddress).agentBurn(operator, tokenId, quantity);
        _burnId.increment();
        uint256 currentBurnId = _burnId.current();
        _burnRecords[currentBurnId] = NftBurnRecord(contractAddress, operator, tokenId);
        emit NftBurnEvent(currentBurnId, quantity, email);
    }
}
