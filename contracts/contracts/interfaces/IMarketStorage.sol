// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketStorage {

    function authorizeToContract(address parentContract, bool authed) external;
}
