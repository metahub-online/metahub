// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol';
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import "../interfaces/ITxnHubNftBase.sol";

abstract contract TxnHubAbstractNFT is Pausable, ERC1155Base, ERC165Base, Ownable, ITxnHubNftBase {
    address private authorizedContract_;
    string private uri_;
    string private name_;
    string private symbol_;

    constructor(string memory _name, string memory _symbol, string memory _uri) {
        uri_ = _uri;
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() external view returns (string memory){
        return name_;
    }

    function setName(string calldata _name) external onlyOwner {
        name_ = _name;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function setSymbol(string calldata _symbol) external onlyOwner {
        symbol_ = _symbol;
    }

    function uri(uint256) external view returns (string memory){
        return uri_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setURI(string memory _uri) external onlyOwner {
        uri_ = _uri;
    }

    function _checkAuthorized() internal view virtual {
        require(_msgSender() == owner() ||
            _msgSender() == authorizedContract_, "");
    }

    modifier authorized() {
        _checkAuthorized();
        _;
    }


    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _agentMint(
        address operator,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _safeMint(to, id, amount, data);
//        emit AgentMint(operator, _msgSender(), to, id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _agentMintBatch(
        address operator,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _safeMintBatch(to, ids, amounts, data);
//        emit AgentMintBatch(operator, _msgSender(), to, ids, amounts);
    }

    function _setAuthorizedContract(address contractAddr) internal virtual {
        authorizedContract_ = contractAddr;
        emit AuthorizedToContract(contractAddr);
    }
}