// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMarketStorage.sol";

interface INftSaleMarket is IMarketStorage {
    struct SellList {
        bool onSale;
        uint64 price;
    }

    event SaleChangeEvent (
        address indexed seller,
        address indexed nftContract,
        uint128 indexed tokenId,
        bool onSale
    );

    function querySaleStatus(address seller_, address nftContractAddr_, uint128 tokenId_) external view returns (
        uint128 balance,
        uint64 price
    );

    function onSale(address operator_,
        address nftContract_,
        uint128 tokenId_,
        uint64 price_
    ) external;

    function cancelSale(address operator_, address nftContractAddr_, uint128 tokenId_) external;


}
