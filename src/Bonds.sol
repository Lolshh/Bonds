// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract Bonds {
    
    uint256 _id;
    mapping(uint256 => address) private _fromID;
    mapping(uint256 => address) private _toID;
    mapping(uint256 => uint256) private _bondsExpiration;
    mapping(uint256 => mapping(uint256 => address)) private _bondsERC20Assets;
    mapping(uint256 => mapping(address => uint256)) private _bondsERC20;

    mapping(uint256 => mapping(uint256 => address)) private _bondsERC721Assets;

    mapping(uint256 => mapping(address => uint256)) private _bondsERC721;

    function addBond(address from, address to, uint256 duration) public {
        _fromID[_id] = from;
        _toID[_id] = to;
        _bondsExpiration[_id] = block.timestamp + duration;
        _id++;
    }

    function updateBondDuration(uint256 bondID, uint256 duration) public bondExistence(bondID) onlyBondOwner(bondID) {
        _bondsExpiration[_id] = block.timestamp + duration;
    }

    function updateBondERC20(uint256 bondID, address asset, uint256 amount) public bondExistence(bondID) onlyBondOwner(bondID) {
        _bondsERC20[bondID][asset] = amount;
        _bondsERC20[bondID][address(0)]++;
        _bondsERC20Assets[bondID][_bondsERC20[bondID][address(0)]] = asset;
        //TODO: Check return value
        IERC20(asset).approve(address(this), amount);
    }

    function batchUpdateBondERC20(uint256 bondID, address[] memory assets, uint256[] memory amounts) public bondExistence(bondID) onlyBondOwner(bondID) {
        require(assets.length == amounts.length, "Arrays' lengths do not match.");
        for (uint i = 0 ; i < assets.length ; i++) {
            updateBondERC20(bondID, assets[i], amounts[i]);
        }
    }

    function performBondERC20(uint256 bondID) public bondExistence(bondID) {
        require (msg.sender == _toID[bondID] && block.timestamp >= _bondsExpiration[bondID], "You cannot retrieve this bond yet.");
        for (uint i = 1 ; i <= _bondsERC20[bondID][address(0)] ; i++) {
            //TODO: Check suffficient balance. Otherwise transfer as much as possible.
            uint256 amount = _bondsERC20[bondID][_bondsERC20Assets[bondID][i]];
            uint256 balance = IERC20(_bondsERC20Assets[bondID][i]).balanceOf(_fromID[bondID]);
            uint256 transfer = amount < balance  ? amount : balance;
            IERC20(_bondsERC20Assets[bondID][i]).transferFrom(_fromID[bondID], _toID[bondID], transfer);
        }
        _fromID[bondID] = address(0);
        _toID[bondID] = address(0);
    }


    function updateBondERC721(uint256 bondID, address asset, uint256 tokenID) public bondExistence(bondID) onlyBondOwner(bondID) {
        _bondsERC721[bondID][asset] = tokenID;
        _bondsERC721[bondID][address(0)]++;
        _bondsERC721Assets[bondID][_bondsERC721[bondID][address(0)]] = asset;
        //TODO: Check return value
        IERC721(asset).approve(address(this), tokenID);
    }

    function batchUpdateBondERC721(uint256 bondID, address[] memory assets, uint256[] memory tokenIDs) public bondExistence(bondID) onlyBondOwner(bondID) {
        require(assets.length == tokenIDs.length, "Arrays' lengths do not match.");
        for (uint i = 0 ; i < assets.length ; i++) {
            updateBondERC20(bondID, assets[i], tokenIDs[i]);
        }
    }

    function performBondERC721(uint256 bondID) public bondExistence(bondID) {
        require (msg.sender == _toID[bondID] && block.timestamp >= _bondsExpiration[bondID], "You cannot retrieve this bond yet.");
        for (uint i = 1 ; i <= _bondsERC721[bondID][address(0)] ; i++) {
            IERC721(_bondsERC721Assets[bondID][i]).transferFrom(_fromID[bondID], _toID[bondID], _bondsERC721[bondID][_bondsERC721Assets[bondID][i]]);
        }
        _fromID[bondID] = address(0);
        _toID[bondID] = address(0);
    }

    function cancelBond(uint256 bondID) public bondExistence(bondID) onlyBondOwner(bondID) {
        _fromID[bondID] = address(0);
        _toID[bondID] = address(0);
    }

    modifier bondExistence(uint256 bondID) {
        require (_fromID[bondID] != address(0), "Bond does not exist.");
        _;
    }

    modifier onlyBondOwner(uint256 bondID) {
        require (msg.sender == _fromID[bondID], "Only owner can update a bond.");
        _;
    }

}
