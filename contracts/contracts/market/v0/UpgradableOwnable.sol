// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract UpgradableOwnable is Context {
    address private _owner;
    mapping(address => bool) _operators;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorConfigured(address indexed operator, bool enable);

    /**
  * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyOperator(){
        _checkOperator();
        _;
    }

    modifier onlyObserver() {
        _checkObserver();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _checkOperator() internal view virtual {
        require(owner() == _msgSender() || _operators[_msgSender()], "Operation: caller is neither owner nor operator");
    }

    function _checkObserver() internal view virtual {
        _checkOperator();
    }

    function isOperator(address addr) public view virtual returns (bool){
        return _operators[addr];
    }

    function configOperator(address addr, bool enable) public virtual onlyOwner {
        _operators[addr] = enable;
        emit OperatorConfigured(addr, enable);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function contractBalance() public view onlyOperator returns (uint256 balance) {
        return address(this).balance;
    }

    function withdrawAll() external onlyOperator {
        uint256 balance = contractBalance();
        require(balance > 0, "not enough balance");
        payable(_owner).transfer(contractBalance());
    }
}
