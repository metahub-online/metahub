// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMarketStorage.sol";
import "./UpgradableOwnableV1.sol";

abstract contract TxnMarketStorageBase is IMarketStorage, UpgradableOwnableV1 {
    mapping(address => bool) private _authorizedContracts;

    modifier onlyAuthContract() {
        _checkAuthedContract();
        _;
    }

    function _checkAuthedContract() internal view {
        require(_authorizedContracts[_msgSender()], 'MarketStorage: not market call');
    }

    function authorizeToContract(address contractAddr, bool authed) external override onlyOwner {
        _authorizedContracts[contractAddr] = authed;
    }

    function authorizedToContract(address contractAddr) external view onlyOwner returns (bool){
        return _authorizedContracts[contractAddr];
    }
}
