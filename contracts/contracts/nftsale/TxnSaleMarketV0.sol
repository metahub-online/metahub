// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../support/TxnMarketStorageBase.sol";
import "../interfaces/INftSaleMarket.sol";
import "../interfaces/ITxnHubSimpleNFT.sol";
import "@solidstate/contracts/interfaces/IERC1155.sol";

contract TxnSaleMarketV0 is TxnMarketStorageBase, INftSaleMarket {

    mapping(address => mapping(address => mapping(uint128 => SellList))) private _saleMapping;

    function initialize() public initializer {
        _transferOwnership(_msgSender());
    }

    function querySaleStatus(address seller_, address nftContractAddr_, uint128 tokenId_) external override view returns (
        uint128 balance,
        uint64 price
    ){
        SellList memory sale = _saleMapping[seller_][nftContractAddr_][tokenId_];
        require(sale.onSale, "Market: not on sale");
        uint128 _balance = uint128(IERC1155(nftContractAddr_).balanceOf(seller_, tokenId_));
        require(_balance > 0, "Market: balance not enough");
        return (_balance, sale.price);
    }

    function onSale(
        address operator_,
        address nftContract_,
        uint128 tokenId_,
        uint64 price_
    ) external override onlyAuthContract {
        require(price_ > 0, "Market: Price must more than 0");
        require(ITxnHubSimpleNFT(nftContract_).isTxnHubSimpleContract(), "ITxnHubSimpleNFT: not Txn Hub NFT");
        require(IERC1155(nftContract_).balanceOf(operator_, tokenId_) > 0, "ITxnHubSimpleNFT: NFT balance is 0");
        _saleMapping[operator_][nftContract_][tokenId_] = SellList(
            true,
            price_);
        emit SaleChangeEvent(operator_, nftContract_, tokenId_, true);
    }

    function cancelSale(address operator_, address nftContractAddr_, uint128 tokenId_) external override onlyAuthContract {
        require(_saleMapping[operator_][nftContractAddr_][tokenId_].onSale, "Market: Already canceled");
        _saleMapping[operator_][nftContractAddr_][tokenId_].onSale = false;
        emit SaleChangeEvent(operator_, nftContractAddr_, tokenId_, false);
    }
}
