// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public merkleAirdrop;
    BagelToken public bagelToken;

    bytes32 public Root =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    bytes32[] public PROOF;

    address public user;
    uint256 public userPrivateKey;
    uint256 private constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 private constant AMOUNT_TO_MINT = AMOUNT_TO_CLAIM * 4;

    function setUp() public {
        bagelToken = new BagelToken();
        merkleAirdrop = new MerkleAirdrop(Root, bagelToken);

        bagelToken.mint(address(merkleAirdrop), AMOUNT_TO_MINT);
        (user, userPrivateKey) = makeAddrAndKey("user");

        PROOF.push(
            0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a
        );
        PROOF.push(
            0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576
        );
    }

    function testClaim() public {
        uint256 startingBalance = bagelToken.balanceOf(user);

        vm.startPrank(user);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF);
        vm.stopPrank();

        uint256 endingBalance = bagelToken.balanceOf(user);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}
