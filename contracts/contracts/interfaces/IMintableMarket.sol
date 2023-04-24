// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITxnHubSimpleNFT.sol";
import "./IMarketStorage.sol";

interface IMintableMarket is IMarketStorage {
    struct GoodsInfo {
        uint32 price;
        bool onSale;
        ITxnHubSimpleNFT nftContract;
    }

    event GoodsOnSaleEvent(uint128 indexed goodsId, bool onSale);

    event MintGoodsEvent(uint128 indexed goodsId,
        address nftContract,
        address mintTo,
        uint128 amount,
        uint128 usdPrice,
        uint256 paidFee,
        uint256 rate
    );

    struct NftBurnRecord {
        address contractAddress;
        address owner;
        uint128 tokenId;
    }

    event NftBurnEvent(uint256 indexed burnId, uint256 quantity, string email);

    function addGoods(uint128 goodsId, address nftContract, uint32 price) external;

    function goodsInfo(uint128 goodsId_) external view returns (GoodsInfo memory goods);

    function goodsOnSale(uint128 goodsId_, bool onSale_) external;

    function mintNft(address operator, uint128 goodsId_, uint128 amount, address to, uint256 paid, uint256 rate) external;

    function burnRecord(uint256 burnId_) external view returns (NftBurnRecord memory);

    function burn(address operator, address contractAddress, uint128 tokenId, uint256 quantity, string calldata email) external;
}
