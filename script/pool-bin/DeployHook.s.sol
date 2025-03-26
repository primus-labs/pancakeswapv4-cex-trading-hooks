// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";

import {BinExchangeVolumeHook} from "../../src/pool-bin/volume/BinExchangeVolumeHook.sol";
import {IAttestationRegistry} from "../../src/IAttestationRegistry.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract DeployHookScript is Script {
    function run() public {
        console.log("msg.sender %s", msg.sender);
        console.log("script %s", address(this));

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address signerAddr = vm.addr(privateKey);
        console.log("SIGNER=%s", signerAddr);

        vm.startBroadcast(privateKey);

        _deploy();

        vm.stopBroadcast();
    }

    function _deploy() internal {
        address _poolManager = vm.envAddress("BIN_POOL_MANAGER");
        console.log("_poolManager=%s", _poolManager);
        address contractOwner = vm.envAddress("CONTRACT_OWNER");
        // Log
        console.log("CONTRACT_OWNER=%s", contractOwner);
        address attestationRegistry = vm.envAddress("ATTESTATION_REGISTRY");
        // Log
        console.log("ATTESTATION_REGISTRY=%s", attestationRegistry);

        BinPoolManager poolManager = BinPoolManager(_poolManager);
        IAttestationRegistry iAttestationRegistry = IAttestationRegistry(attestationRegistry);
        BinExchangeVolumeHook hook = new BinExchangeVolumeHook(poolManager, iAttestationRegistry, contractOwner);
        console.log("BIN_HOOK=%s", address(hook));
    }
}
/*
forge script script/pool-bin/DeployHook.s.sol --rpc-url bsc --broadcast
*/
