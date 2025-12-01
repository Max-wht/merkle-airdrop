// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    address[] public claimants;
    bytes32 public merkleRoot;
    IERC20 public immutable AIRDROP_TOKEN;

    mapping(address claimer => bool claimed) public claimedMap;

    event Claimed(address indexed account, uint256 amount);

    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) {
        merkleRoot = _merkleRoot;
        AIRDROP_TOKEN = _airdropToken;
    }

    function claim(
        address _account,
        uint256 _amount,
        bytes32[] memory _proof
    ) external {
        if (claimedMap[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // avoid collisions (second-preimage attack)
        // use inline assembly for gas efficiency
        bytes32 leaf;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _account)
            mstore(add(ptr, 0x20), _amount)
            let innerHash := keccak256(ptr, 0x40)
            mstore(ptr, innerHash)
            leaf := keccak256(ptr, 0x20)
        }

        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        emit Claimed(_account, _amount);

        claimedMap[_account] = true;
        AIRDROP_TOKEN.safeTransfer(_account, _amount);
    }

    function getTokenAddress() external view returns (address) {
        return address(AIRDROP_TOKEN);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }
}
