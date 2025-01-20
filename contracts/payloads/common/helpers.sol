pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {BigMathMinified} from "../libraries/bigMathMinified.sol";
import {LiquidityCalcs} from "../libraries/liquidityCalcs.sol";
import {LiquiditySlotsLink} from "../libraries/liquiditySlotsLink.sol";

import { IGovernorBravo } from "./interfaces/IGovernorBravo.sol";
import { ITimelock } from "./interfaces/ITimelock.sol";

import { IFluidLiquidityAdmin, AdminModuleStructs as FluidLiquidityAdminStructs } from "./interfaces/IFluidLiquidity.sol";
import { IFluidReserveContract } from "./interfaces/IFluidReserveContract.sol";

import { IFluidVaultFactory } from "./interfaces/IFluidVaultFactory.sol";
import { IFluidDexFactory } from "./interfaces/IFluidDexFactory.sol";

import { IFluidDex, IFluidAdminDex } from "./interfaces/IFluidDex.sol";
import { IFluidDexResolver } from "./interfaces/IFluidDex.sol";

import { IFluidVault } from "./interfaces/IFluidVault.sol";
import { IFluidVaultT1 } from "./interfaces/IFluidVault.sol";

import { IFTokenAdmin } from "./interfaces/IFToken.sol";
import { ILendingRewards } from "./interfaces/IFToken.sol";

import { IDSAV2 } from "./interfaces/IDSA.sol";

import { PayloadIGPConstants } from "./constants.sol";


contract PayloadIGPHelpers is PayloadIGPConstants {
    /**
     * |
     * |     Proposal Payload Helpers      |
     * |__________________________________
     */
    function getVaultAddress(uint256 vaultId_) public view returns (address) {
        return VAULT_FACTORY.getVaultAddress(vaultId_);
    }

    function getDexAddress(uint256 dexId_) public view returns (address) {
        return DEX_FACTORY.getDexAddress(dexId_);
    }

    struct SupplyProtocolConfig {
        address protocol;
        address supplyToken;
        uint256 expandPercent;
        uint256 expandDuration;
        uint256 baseWithdrawalLimitInUSD;
    }

    struct BorrowProtocolConfig {
        address protocol;
        address borrowToken;
        uint256 expandPercent;
        uint256 expandDuration;
        uint256 baseBorrowLimitInUSD;
        uint256 maxBorrowLimitInUSD;
    }

    function setSupplyProtocolLimits(
        SupplyProtocolConfig memory protocolConfig_
    ) internal {
        {
            // Supply Limits
            FluidLiquidityAdminStructs.UserSupplyConfig[]
                memory configs_ = new FluidLiquidityAdminStructs.UserSupplyConfig[](1);

            configs_[0] = FluidLiquidityAdminStructs.UserSupplyConfig({
                user: address(protocolConfig_.protocol),
                token: protocolConfig_.supplyToken,
                mode: 1,
                expandPercent: protocolConfig_.expandPercent,
                expandDuration: protocolConfig_.expandDuration,
                baseWithdrawalLimit: getRawAmount(
                    protocolConfig_.supplyToken,
                    0,
                    protocolConfig_.baseWithdrawalLimitInUSD,
                    true
                )
            });

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }
    }

    function setBorrowProtocolLimits(
        BorrowProtocolConfig memory protocolConfig_
    ) internal {
        {
            // Borrow Limits
            FluidLiquidityAdminStructs.UserBorrowConfig[]
                memory configs_ = new FluidLiquidityAdminStructs.UserBorrowConfig[](1);

            configs_[0] = FluidLiquidityAdminStructs.UserBorrowConfig({
                user: address(protocolConfig_.protocol),
                token: protocolConfig_.borrowToken,
                mode: 1,
                expandPercent: protocolConfig_.expandPercent,
                expandDuration: protocolConfig_.expandDuration,
                baseDebtCeiling: getRawAmount(
                    protocolConfig_.borrowToken,
                    0,
                    protocolConfig_.baseBorrowLimitInUSD,
                    false
                ),
                maxDebtCeiling: getRawAmount(
                    protocolConfig_.borrowToken,
                    0,
                    protocolConfig_.maxBorrowLimitInUSD,
                    false
                )
            });

            LIQUIDITY.updateUserBorrowConfigs(configs_);
        }
    }


    struct DexBorrowProtocolConfigInShares {
        address dex;
        address protocol;
        uint256 expandPercent;
        uint256 expandDuration;
        uint256 baseBorrowLimit;
        uint256 maxBorrowLimit;
    }

    function setDexBorrowProtocolLimitsInShares(
        DexBorrowProtocolConfigInShares memory protocolConfig_
    ) internal {
        IFluidAdminDex.UserBorrowConfig[]
            memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
        config_[0] = IFluidAdminDex.UserBorrowConfig({
            user: protocolConfig_.protocol,
            expandPercent: protocolConfig_.expandPercent,
            expandDuration: protocolConfig_.expandDuration,
            baseDebtCeiling: protocolConfig_.baseBorrowLimit,
            maxDebtCeiling: protocolConfig_.maxBorrowLimit
        });

        IFluidDex(protocolConfig_.dex).updateUserBorrowConfigs(
            config_
        );
    }

    function getRawAmount(
        address token,
        uint256 amount,
        uint256 amountInUSD,
        bool isSupply
    ) public virtual view returns (uint256) {
        return 0;
    }
}
