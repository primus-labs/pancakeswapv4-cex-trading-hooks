// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {LPFeeLibrary} from "pancake-v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {IAttestationRegistry} from "./IAttestationRegistry.sol";
import {Attestation} from "./types/Common.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract BaseFeeDiscountHook is Ownable {
    using LPFeeLibrary for uint24;

    event BeforeAddLiquidity(address indexed sender);
    event BeforeSwap(address indexed sender);

    event DefaultFeeChanged(uint24 oldFee, uint24 newFee);
    event BaseValueChanged(uint24 oldBaseValue, uint24 newBaseValue);
    event DurationOfAttestationChanged(uint24 oldDurationOfAttestation, uint24 newDurationOfAttestation);
    event AttestationRegistryChanged(address oldAttestationRegistry, address newAttestationRegistry);

    uint24 public defaultFee = 3000;

    uint24 public baseValue = 10000;

    uint24 public durationOfAttestation = 7;

    PoolId[] public poolsInitialized;

    mapping(PoolId => uint24) public poolFeeMapping;

    // AttestationRegistry
    IAttestationRegistry public iAttestationRegistry;

    constructor(IAttestationRegistry _iAttestationRegistry, address initialOwner) Ownable(initialOwner) {
        iAttestationRegistry = _iAttestationRegistry;
    }

    function getFeeDiscount(address sender, PoolKey memory poolKey) internal view returns (uint24) {
        uint24 poolFee = poolFeeMapping[poolKey.toId()];
        if (_checkAttestations(sender)) {
            return (poolFee / 2) | LPFeeLibrary.OVERRIDE_FEE_FLAG;
        }
        return poolFee;
    }

    /*
      @dev Set default fee for pool
      @param fee
      @return
     */
    function setDefaultFee(uint24 fee) external onlyOwner {
        emit DefaultFeeChanged(defaultFee, fee);
        defaultFee = fee;
    }

    /*
    @dev Set baseValue
      @param _baseValue
      @return
     */
    function setBaseValue(uint24 _baseValue) external onlyOwner {
        emit BaseValueChanged(baseValue, _baseValue);
        baseValue = _baseValue;
    }

    /*
      @dev Set durationOfAttestation
      @param _durationOfAttestation
      @return
     */
    function setDurationOfAttestation(uint24 _durationOfAttestation) external onlyOwner {
        emit DurationOfAttestationChanged(durationOfAttestation, _durationOfAttestation);
        durationOfAttestation = _durationOfAttestation;
    }

    /*
      @dev Set attestationRegistry
     */
    function setAttestationRegistry(IAttestationRegistry _iAttestationRegistry) external onlyOwner {
        emit AttestationRegistryChanged(address(iAttestationRegistry), address(_iAttestationRegistry));
        iAttestationRegistry = _iAttestationRegistry;
    }

    /*
      @dev Get initialized pool size
      @return uint
     */
    function getInitializedPoolSize() external view returns (uint256) {
        return poolsInitialized.length;
    }

    /*
      @dev Check the user has a attestation and the attestation is not expired
      @param sender
      @return bool , sender has valid attestation.
     */
    function _checkAttestations(address sender) internal view returns (bool) {
        // Get attestations for the sender
        Attestation[] memory attestations = iAttestationRegistry.getAttestationByRecipient(sender);
        if (attestations.length == 0) {
            return false;
        }
        // Iterate through the attestations
        for (uint256 i = attestations.length; i > 0; i--) {
            Attestation memory attestation = attestations[i - 1];
            // Ensure attestation has a valid timestamp field
            if (
                (block.timestamp - attestation.timestamp / 1000) <= durationOfAttestation * 24 * 60 * 60
                    && attestation.value >= baseValue
            ) {
                return true;
            }
        }
        // No valid attestations found
        return false;
    }
}
