//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "../src/Bonds.sol";

contract BondsTest is Test {

    address deployer = makeAddr("deployer");
    address facticeUser1 = makeAddr("facticeUser1");
	address facticeUser2 = makeAddr("facticeUser2");
    address facticeUser3 = makeAddr("facticeUser3");

    address public constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address public constant usdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    IERC20 WETH = IERC20(wethAddr);
	IERC20 USDC = IERC20(usdcAddr);

    Bonds bond_contract;

    function createContract() public{

        vm.createSelectFork("https://rpc.ankr.com/eth", 16_153_817); // eth mainnet at block 16_153_817
	    
        deal(usdcAddr, facticeUser1, 100_000 * 10**6);
	    deal(wethAddr, facticeUser1, 100 ether);
        
        USDC.approve(address(facticeUser1), 100_000 * 10**6);
		WETH.approve(address(facticeUser1), 100 ether);

        vm.startPrank(deployer);
        bond_contract = new Bonds();
        vm.stopPrank();
    }
    
    function testCreateBond() public returns(uint256) {
        createContract();
        vm.startPrank(facticeUser1);
        uint256 bondID = bond_contract.addBond(facticeUser1, facticeUser2, 2 days);
        vm.stopPrank();
        return bondID;
    }

    function testUpdateBond() public returns(uint256) {
        uint256 bondID = testCreateBond();
        vm.startPrank(facticeUser1);
        bond_contract.updateBondERC20(bondID, usdcAddr, 10000 * 10**6);
        USDC.approve(address(bond_contract), 10000*10**6);
        vm.stopPrank();
        
        return bondID;
    }

    function testPerformBond() public {
        uint256 bondID = testUpdateBond();
        vm.warp(block.timestamp + 2 days);
        vm.startPrank(facticeUser2);
        bond_contract.performBondERC20(bondID);
        vm.stopPrank();
    }   

    function testPerformBondBeforeEnd() public {
        uint256 bondID = testUpdateBond();
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(facticeUser2);
        vm.expectRevert();
        bond_contract.performBondERC20(bondID);
        vm.stopPrank();
    }

    function testCancelBond() public returns(uint256) {
        uint256 bondID = testUpdateBond();
        vm.startPrank(facticeUser1);
        bond_contract.cancelBond(bondID);
        vm.stopPrank();
        return bondID;
    }

    function testPerformCanceledBond() public {
        uint256 bondID = testCancelBond();
        vm.expectRevert();
        vm.warp(block.timestamp + 2 days);
        vm.startPrank(facticeUser2);
        bond_contract.performBondERC20(bondID);
        vm.stopPrank();
    }

    function testPerformBondDifferentUser() public {
        uint256 bondID = testUpdateBond();
        vm.warp(block.timestamp + 2 days);
        vm.startPrank(facticeUser3);
        vm.expectRevert();
        bond_contract.performBondERC20(bondID);
        vm.stopPrank();
    }


    function testPerformBondUnsufficientBalance() public {
        uint256 bondID = testCreateBond();
        vm.startPrank(facticeUser1);
        bond_contract.updateBondERC20(bondID, usdcAddr, 1000000 * 10**6);
        USDC.approve(address(bond_contract), 1000000*10**6);
        vm.stopPrank();
        vm.warp(block.timestamp + 2 days);
        vm.startPrank(facticeUser2);
        bond_contract.performBondERC20(bondID);
        vm.stopPrank();
        console.log(USDC.balanceOf(facticeUser2));
        
    }


}