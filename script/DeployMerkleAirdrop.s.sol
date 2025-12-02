// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public constant ROOT =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    uint256 public constant AMOUNT_TO_MINT = 25 * 1e18 * 4;

    // 用于真实部署（带 broadcast）
    function run() public returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        (MerkleAirdrop merkleAirdrop, BagelToken bagelToken) = deployAirdrop();
        vm.stopBroadcast();
        return (merkleAirdrop, bagelToken);
    }

    // 用于测试（不带 broadcast，zkSync 和 EVM 都可用）
    function deployAirdrop() public returns (MerkleAirdrop, BagelToken) {
        BagelToken bagelToken = new BagelToken();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(
            ROOT,
            IERC20(address(bagelToken))
        );
        bagelToken.mint(bagelToken.owner(), AMOUNT_TO_MINT);
        bagelToken.transfer(address(merkleAirdrop), AMOUNT_TO_MINT);

        return (merkleAirdrop, bagelToken);
    }
}
