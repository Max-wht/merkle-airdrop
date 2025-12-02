// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {DevOpsTools} from "@foundry-devops/DevOpsTools.sol";

contract ClaimAirdrop is Script {
    error __ClaimAirdrop__InvalidSignatureFormat();

    address constant CLAIM_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant AMOUNT_TO_CLAIM = 25 * 1e18;
    bytes32 proof1 =
        0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 proof2 =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [proof1, proof2];
    bytes private SIGNATURE =
        hex"12e145324b60cd4d302bfad59f72946d45ffad8b9fd608e672fd7f02029de7c438cfa0b8251ea803f361522da811406d441df04ee99c3dc7d65f8550e12be2ca1c";

    function clainAirdrop(address _airdrop) internal {
        (uint8 v, bytes32 r, bytes32 s) = seprateSignature(SIGNATURE);
        vm.startBroadcast();
        MerkleAirdrop(_airdrop).claim(
            CLAIM_ADDRESS,
            AMOUNT_TO_CLAIM,
            proof,
            v,
            r,
            s
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecent = DevOpsTools.get_most_recent_deployment(
            "MerkleAirdrop",
            block.chainid
        );
        clainAirdrop(mostRecent);
    }

    function seprateSignature(
        bytes memory _signature
    ) public returns (uint8 v, bytes32 r, bytes32 s) {
        if (_signature.length != 65) {
            revert __ClaimAirdrop__InvalidSignatureFormat();
        }
        // in the case of `cast wallet sign` the signature is in the format of `r,s,v`
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        return (v, r, s);
    }
}
