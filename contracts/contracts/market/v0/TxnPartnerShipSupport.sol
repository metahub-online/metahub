// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./UpgradableOwnable.sol";

contract TxnPartnerShipSupport is UpgradableOwnable {
    using SafeMath for uint256;

    struct PartnerShip {
        bool enable;
        uint8 level;//优惠等级(0-5),0级全价，1级50%平台折扣，2级60%平台折扣，3级70%平台折扣，4级80%平台折扣，5级90%平台折扣
        uint32 shareRate;//手续费分成比例（1=千分之一）
    }

    event PartnerChanged(address indexed partnerAddress, bool enable);
    event PartnerBalanceChanged(address indexed partnerAddress, uint256 balance, string reason);

    mapping(address => PartnerShip) private _partners;
    mapping(address => uint256) private _recipient;

    modifier ownerOrPartner() {
        require(_msgSender() == owner()|| isOperator(_msgSender()) || _partners[_msgSender()].enable, "TxnPartnerShip: Must be owner or partner");
        _;
    }

    modifier onlyPartner() {
        require(_partners[_msgSender()].enable, "TxnPartnerShip: Must be owner or partner");
        _;
    }

    function _getPartner(address partnerAddress) internal view virtual returns (PartnerShip memory) {
        return _partners[partnerAddress];
    }

    function getPartnerInfo(address partnerAddress) external view onlyOperator returns (PartnerShip memory){
        require(_partners[partnerAddress].enable, "TxnPartnerShip: Partner not exists");
        return _getPartner(partnerAddress);
    }

    function setPartnerShip(address partnerAddress,
        uint8 level,
        uint32 shareRate) public virtual onlyOperator {
        require(shareRate < 1000, "TxnPartnerShip: share rate shall be lower than 100%");
        require(level >= 0 && level <= 5, "TxnPartnerShip: invalid level");
        PartnerShip memory exists = _partners[partnerAddress];
        _partners[partnerAddress] = PartnerShip(true, level, shareRate);
        if (!exists.enable) {
            emit PartnerChanged(partnerAddress, true);
        }
    }

    function isPartner(address partnerAddress) external view returns (bool) {
        return _partners[partnerAddress].enable;
    }

    function disablePartner(address partnerAddress) public virtual onlyOperator {
        PartnerShip memory exists = _partners[partnerAddress];
        if (exists.enable) {
            _partners[partnerAddress].enable = false;
            emit PartnerChanged(partnerAddress, false);
        }
    }

    function partnerWithdraw(address to) external {
        require(_partners[to].enable, "TxnPartnerShip: target not partner");
        require(_msgSender() == owner() || _msgSender() == to, "TxnPartnerShip: not owner or partner");
        require(_recipient[to] > 0, "TxnPartnerShip: balance is 0");
        payable(to).transfer(_recipient[to]);
        _recipient[to] = 0;
        emit PartnerBalanceChanged(to, 0, "Withdraw");
    }

    function partnerBalance(address partner) external view ownerOrPartner returns (uint256){
        require(_msgSender() == owner() || _msgSender() == partner, "TxnPartnerShip: forbidden visit");
        return _recipient[partner];
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        payable(_msgSender()).transfer(amount);
    }

    function _shareRecipient(address partner, uint256 fee) internal virtual returns (bool) {
        PartnerShip memory partnerShip = _partners[partner];
        if (partnerShip.enable) {
            uint256 shareFee = partnerShip.shareRate * fee / 1000;
            if(shareFee>0){
                _recipient[partner] += shareFee;
                emit PartnerBalanceChanged(partner, _recipient[partner], "share");
                return true;
            }
        }
        return false;
    }

}
