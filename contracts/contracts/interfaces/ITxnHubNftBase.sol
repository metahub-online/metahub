// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/interfaces/IERC1155.sol";
import "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

interface ITxnHubNftBase is IERC1155, IERC1155Metadata{
    event AuthorizedToContract(address contractAddress);
    event AgentMint(address operator,
        address sender,
        address indexed to,
        uint256 id,
        uint256 amount
    );
    event AgentMintBatch(address operator,
        address sender,
        address indexed to,
        uint256[] id,
        uint256[] amount
    );
}
