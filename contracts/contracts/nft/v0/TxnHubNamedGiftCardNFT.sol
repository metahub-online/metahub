// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol';
import "../../interfaces/ITxnHubNFT.sol";
import "../TxnHubAbstractNFT.sol";

contract TxnHubNamedGiftCardNFT is TxnHubAbstractNFT, ERC1155Enumerable, ITxnHubNFT {
    using Counters for Counters.Counter;
    Counters.Counter private _currentTokenId;

    constructor (string memory name, string memory symbol, string memory _uri) TxnHubAbstractNFT(name, symbol, _uri){
    }

    function maxTokenId() public view returns (uint256){
        return (_currentTokenId.current());
    }

    function agentMint(address operator, address to, uint256 amount, bytes memory data) external virtual override authorized whenNotPaused
    returns (uint256){
        _currentTokenId.increment();
        uint256 current = _currentTokenId.current();
        _agentMint(operator, to, current, amount, data);
        return (current);
    }

    function agentMintBatch(address operator, address to, uint256[] memory amounts, bytes memory data) external virtual override authorized whenNotPaused returns (uint256[] memory){
        uint amountsLength = amounts.length;
        uint256[] memory tokens = new uint256[](amountsLength);
        for (uint256 index = 0; index < amountsLength; index++) {
            _currentTokenId.increment();
            uint256 token = _currentTokenId.current();
            tokens[index] = token;
        }
        _agentMintBatch(operator, to, tokens, amounts, data);
        return tokens;
    }

    function agentBurnSingle(address from, uint256 id) external virtual override authorized whenNotPaused {
        _burn(from, id, 1);
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

    function isTxnHubContract() external pure returns (bool){
        return true;
    }

    function setAuthorizedContract(address contractAddr) external onlyOwner {
        _setAuthorizedContract(contractAddr);
    }
}