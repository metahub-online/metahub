// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMarketStorage.sol";

interface IMarketRoleManager is IMarketStorage {
    event RoleAuthEvent(address indexed account, uint8 roleId, bool enable);

    function hasRole(address account, uint8 roleId) external view returns (bool);

    function triggerRole(address account, uint8 roleId, bool enable, bool single) external;

    function findRoleSingleAccount(uint8 roleId) external view returns (address);
}
