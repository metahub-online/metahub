// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import '@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol';
import "../../interfaces/ITxnHubSimpleNFT.sol";
import "../TxnHubAbstractNFT.sol";

contract TxnHubSimpleGiftCardNFT is TxnHubAbstractNFT, ERC1155Enumerable, ITxnHubSimpleNFT {

    constructor (string memory name, string memory symbol, string memory _uri) TxnHubAbstractNFT(name, symbol, _uri){
    }


    function agentMintId(address operator, address to, uint256 id, uint256 amount, bytes memory data) external virtual override authorized whenNotPaused {
        _agentMint(operator, to, id, amount, data);
    }

    function agentMintIdBatch(address operator, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes memory data) external virtual override authorized whenNotPaused{
        _agentMintBatch(operator, to, ids, amounts, data);
    }

    function agentBurn(address from, uint256 id, uint256 amount) external virtual override authorized whenNotPaused {
        _burn(from, id, amount);
    }

    /**
    * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155EnumerableInternal, ERC1155BaseInternal) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function isTxnHubSimpleContract() external pure returns (bool){
        return true;
    }

    function setAuthorizedContract(address contractAddr) external onlyOwner {
        _setAuthorizedContract(contractAddr);
    }
}