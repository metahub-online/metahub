// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract UsdtSampleMarketTest0 is Ownable {

    IERC20 private _usdt_contract;
    address private _asset_user;
    uint256 private _test_price;

    event PayUsdtEvt(address indexed payer, uint256 amt);
    constructor(address usdt_contract, address asset, uint256 test_price){
        _usdt_contract = IERC20(usdt_contract);
        _asset_user = asset;
        _test_price = test_price;
    }

    function changeAsset(address user) external onlyOwner {
        require(user != address(0), 'No 0 address');
        require(user != _asset_user, 'Same user');
        _asset_user = user;
    }

    function currentAssetUser() external view onlyOwner returns (address) {
        return _asset_user;
    }

    function changePrice(uint256 new_price) external onlyOwner {
        _test_price = new_price;
    }

    function currentPrice() view external returns (uint256) {
        return _test_price;
    }


    function payUsdt() external {
        uint256 allowance_amt = _usdt_contract.allowance(msg.sender, address(this));
        require(allowance_amt >= _test_price, 'Allowance balance not enough');
        _usdt_contract.transferFrom(msg.sender, _asset_user, _test_price);
        emit PayUsdtEvt(msg.sender, _test_price);
    }
}
