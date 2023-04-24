// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITxnHubNftBase.sol";

interface ITxnHubSimpleNFT is ITxnHubNftBase {

    function agentMintId(address operator, address to, uint256 id, uint256 amount, bytes memory data) external;

    function agentMintIdBatch(address operator, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function agentBurn(address from, uint256 id, uint256 amount) external;

    function isTxnHubSimpleContract() external pure returns (bool);
}
