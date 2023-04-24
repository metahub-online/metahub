// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ContractBitMathTest {
    using SafeMath for uint256;
    constructor(){

    }

    function maskPrice(uint16 stableId, uint256 fee) pure public returns (uint256) {
        uint256 finalPrice = uint256(stableId)<<240;
        finalPrice = finalPrice | fee;
        return finalPrice;
    }
}
