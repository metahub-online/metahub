// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITxnHubNftBase.sol";

interface ITxnHubNFT is ITxnHubNftBase {


    function agentMint(address operator, address to, uint256 amount, bytes memory data) external returns (uint256);

    function agentMintBatch(address operator, address to, uint256[] memory amounts, bytes memory data) external returns (uint256[] memory);

    function agentBurnSingle(address from, uint256 id) external;

    function isTxnHubContract() external pure returns (bool);
}
