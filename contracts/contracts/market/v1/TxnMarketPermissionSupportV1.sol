// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IMarketRoleManager.sol";
import "../../support/UpgradableOwnableV1.sol";

/**
 * @dev Role Definition:
 * - ROOT, config sensitive contract.
 * - OPERATOR=1, able to manage goods, contract args
 * - OBSERVER=2, web2 backend process
 * - ASSET=3, single account, account for withdraw
 */
abstract contract TxnMarketPermissionSupportV1 is UpgradableOwnableV1 {
    IMarketRoleManager private _roleManager;


    function updateRoleManager(address contractAddr) public onlyOwner {
        _roleManager = IMarketRoleManager(contractAddr);
    }

    function _checkOperator() internal view virtual {
        require(owner() == _msgSender() || _isRole(_msgSender(), 1) || _isRole(_msgSender(), 3), "Operation: caller is neither owner nor operator");
    }

    function _isRole(address account, uint8 role) internal view virtual returns (bool) {
        return _roleManager.hasRole(account, role);
    }

    function isOperator(address account) external view returns (bool) {
        return _isRole(account, 1);
    }

    function isObserver(address account) external view returns (bool) {
        return _isRole(account, 2);
    }

    function currentAsset() public view returns (address) {
        return _roleManager.findRoleSingleAccount(3);
    }

    function _checkObserver() internal view virtual {
        require(owner() == _msgSender() || _isRole(_msgSender(), 1) || _isRole(_msgSender(), 2), "Operation: caller is neither owner nor operator nor observer");
    }

    function configOperator(address account, bool enable) external onlyOwner {
        _roleManager.triggerRole(account, 1, enable, false);
    }

    function configObserver(address account, bool enable) external onlyOwner {
        _roleManager.triggerRole(account, 2, enable, false);
    }

    function configAssetAccount(address account) external onlyOwner {
        _roleManager.triggerRole(account, 3, true, true);
    }

    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    modifier onlyObserver(){
        _checkObserver();
        _;
    }

}
