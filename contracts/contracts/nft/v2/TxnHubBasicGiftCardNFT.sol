// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TxnHubAbstractNFT.sol";
import "../../interfaces/ITxnHubSimpleNFT.sol";

contract TxnHubBasicGiftCardNFT is TxnHubAbstractNFT, ITxnHubSimpleNFT {

    constructor(string memory name, string memory symbol, string memory _uri) TxnHubAbstractNFT(name, symbol, _uri){
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

    function isTxnHubSimpleContract() external pure returns (bool){
        return true;
    }

    function setAuthorizedContract(address contractAddr) external onlyOwner {
        _setAuthorizedContract(contractAddr);
    }
}
