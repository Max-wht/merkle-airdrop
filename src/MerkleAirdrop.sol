// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    address[] public claimants;
    bytes32 public merkleRoot;
    IERC20 public immutable AIRDROP_TOKEN;
    mapping(address claimer => bool claimed) public claimedMap;

    bytes32 public constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claimed(address indexed account, uint256 amount);

    constructor(
        bytes32 _merkleRoot,
        IERC20 _airdropToken
    ) EIP712("MerkleAirdrop", "1") {
        merkleRoot = _merkleRoot;
        AIRDROP_TOKEN = _airdropToken;
    }

    function claim(
        address _account,
        uint256 _amount,
        bytes32[] memory _proof,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (claimedMap[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if (
            !_isValidSignature(
                _account,
                getDigest(_account, _amount),
                _v,
                _r,
                _s
            )
        ) {
            revert MerkleAirdrop__InvalidSignature();
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

    function getDigest(
        address _account,
        uint256 _amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MESSAGE_TYPEHASH,
                        AirdropClaim({account: _account, amount: _amount})
                    )
                )
            );
    }

    function _isValidSignature(
        address _account,
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(_digest, _v, _r, _s);
        return actualSigner == _account;
    }

    function getTokenAddress() external view returns (address) {
        return address(AIRDROP_TOKEN);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }
}
