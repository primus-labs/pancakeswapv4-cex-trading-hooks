// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import "forge-std/Test.sol";
import {AttestationRegistry} from "src/attestation/AttestationRegistry.sol";

contract DeployAttestationRegistry is Script {
    function run() external {
        // private key from env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // initialize variables from env
        address primusZKTLS = vm.envAddress("PRIMUS_ZKTLS"); // IPrimusZKTLS contract address
        uint256 submissionFee = 300000000000000; // submit fee
        address payable feeRecipient = payable(vm.envAddress("FEE_RECIPIENT")); // fee recipient

        // deploy AttestationRegistry
        AttestationRegistry attestationRegistry = new AttestationRegistry(primusZKTLS, submissionFee, feeRecipient);
        string[] memory cexUrls = new string[](4);
        cexUrls[0] = "https://www.okx.com/v3/users/fee/trading-volume-progress";
        cexUrls[1] = "https://www.bitget.com/v1/mix/vip/need";
        cexUrls[2] = "https://www.binance.com/bapi/accounts/v1/private/vip/vip-portal/vip-fee/vip-programs-and-fees";
        cexUrls[3] = "https://api2.bybit.com/s1/loyalty-program/get-vip-detail";
        string[] memory cexJsonPaths = new string[](4);
        cexJsonPaths[0] = "$.data.requirements[1].currentVolume";
        cexJsonPaths[1] = "$.data.spotVol";
        cexJsonPaths[2] = "$.data.traderProgram.spotTrader.spotVolume30d";
        cexJsonPaths[3] = "$.result.vip_info.spot_txn_volum";
        string[] memory cexNames = new string[](4);
        cexNames[0] = "okx";
        cexNames[1] = "bitget";
        cexNames[2] = "binance";
        cexNames[3] = "bybit";
        attestationRegistry.setCexAndJsonPath(cexUrls, cexNames, cexJsonPaths);

        console.log("AttestationRegistry deployed at:", address(attestationRegistry));

        vm.stopBroadcast();
    }
}


// forge script script/attestation/AttestationRegistry.s.sol --rpc-url bsc --broadcast