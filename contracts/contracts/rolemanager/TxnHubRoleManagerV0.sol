// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../support/TxnMarketStorageBase.sol";
import "../interfaces/IMarketRoleManager.sol";

contract TxnHubRoleManagerV0 is TxnMarketStorageBase, IMarketRoleManager {
    mapping(uint8 => mapping(address => bool)) private _authedAccount;
    mapping(uint8 => address) private _singleRoleAccounts;

    function initialize() public initializer {
        _transferOwnership(_msgSender());
    }

    function triggerRole(address account, uint8 roleId, bool enable, bool single) external override onlyAuthContract {
        if (single) {
            if (enable) {
                _singleRoleAccounts[roleId] = account;
            } else {
                _singleRoleAccounts[roleId] = address(0);
            }
        } else {
            _authedAccount[roleId][account] = enable;
        }
        emit RoleAuthEvent(account, roleId, enable);
    }

    function hasRole(address account, uint8 roleId) external view override returns (bool) {
        return _authedAccount[roleId][account] || _singleRoleAccounts[roleId] == account;
    }

    function findRoleSingleAccount(uint8 roleId) external view override returns (address){
        return _singleRoleAccounts[roleId];
    }
}
