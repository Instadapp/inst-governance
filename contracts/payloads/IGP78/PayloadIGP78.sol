pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {BigMathMinified} from "../libraries/bigMathMinified.sol";
import {LiquidityCalcs} from "../libraries/liquidityCalcs.sol";
import {LiquiditySlotsLink} from "../libraries/liquiditySlotsLink.sol";

import {IGovernorBravo} from "../common/interfaces/IGovernorBravo.sol";
import {ITimelock} from "../common/interfaces/ITimelock.sol";

import {IFluidLiquidityAdmin, AdminModuleStructs as FluidLiquidityAdminStructs} from "../common/interfaces/IFluidLiquidity.sol";
import {IFluidReserveContract} from "../common/interfaces/IFluidReserveContract.sol";

import {IFluidVaultFactory} from "../common/interfaces/IFluidVaultFactory.sol";
import {IFluidDexFactory} from "../common/interfaces/IFluidDexFactory.sol";

import {IFluidDex, IFluidAdminDex, IFluidDexResolver} from "../common/interfaces/IFluidDex.sol";

import {IFluidVault, IFluidVaultT1} from "../common/interfaces/IFluidVault.sol";

import {IFTokenAdmin, ILendingRewards} from "../common/interfaces/IFToken.sol";

import {IDSAV2} from "../common/interfaces/IDSA.sol";
import {IERC20} from "../common/interfaces/IERC20.sol";
import {IProxy} from "../common/interfaces/IProxy.sol";
import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";

contract PayloadIGP78 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 78;

    function propose(string memory description) external {
        require(
            msg.sender == PROPOSER ||
                msg.sender == TEAM_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG_2 ||
                address(this) == PROPOSER_AVO_MULTISIG_3 ||
                address(this) == PROPOSER_AVO_MULTISIG_4 ||
                address(this) == PROPOSER_AVO_MULTISIG_5,
            "msg.sender-not-allowed"
        );

        uint256 totalActions = 1;
        address[] memory targets = new address[](totalActions);
        uint256[] memory values = new uint256[](totalActions);
        string[] memory signatures = new string[](totalActions);
        bytes[] memory calldatas = new bytes[](totalActions);

        targets[0] = address(TIMELOCK);
        values[0] = 0;
        signatures[0] = "executePayload(address,string,bytes)";
        calldatas[0] = abi.encode(ADDRESS_THIS, "execute()", abi.encode());

        uint256 proposedId = GOVERNOR.propose(
            targets,
            values,
            signatures,
            calldatas,
            description
        );

        require(proposedId == PROPOSAL_ID, "PROPOSAL_IS_NOT_SAME");
    }

    function execute() external {
        require(address(this) == address(TIMELOCK), "not-valid-caller");

        // Action 1: Set initial limits for sUSDe-USDT dex and vault
        action1();

        // Action 2: Set initial limits for USDe-USDT dex and vault
        action2();

        // Action 3: Set initial limits for eBTC-cbBTC dex and vault
        action3();

        // Action 4: Set initial limits for lBTC-cbBTC dex and vault
        action4();

        // Action 5: Update USDC-USDT Dex Config
        action5();

        // Action 6: Update wstETH-ETH Dex Config
        action6();

        // Action 7: Update vault deployment logics on vault factory
        action7();

        // Action 8: Remove sUSDe handlers
        action8();
    }

    // @notice Action 1: Set initial limits for sUSDe-USDT dex and vault
    function action1() internal {
        address sUSDe_USDT_DEX = getDexAddress(15);
        address sUSDe_USDT__USDT_VAULT = getVaultAddress(0); // TODO
        {
            // sUSDe-USDT DEX
            {
                // sUSDe-USDT Dex
                Dex memory DEX_sUSDe_USDT = Dex({
                    dex: sUSDe_USDT_DEX,
                    tokenA: sUSDe_ADDRESS,
                    tokenB: USDT_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_sUSDe_USDT); // Smart Collateral

                DEX_FACTORY.setDexAuth(sUSDe_USDT_DEX, TEAM_MULTISIG, true);
            }
        }

        {
            // [TYPE 2] sUSDe-USDT<>USDT | smart collateral & debt
            Vault memory VAULT_sUSDe_USDT = Vault({
                vault: sUSDe_USDT__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_sUSDe_USDT); // TYPE_2 => 0 // TODO

            VAULT_FACTORY.setVaultAuth(
                sUSDe_USDT__USDT_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 2: Set initial limits for USDe-USDT dex and vault
    function action2() internal {
        address USDe_USDT_DEX = getDexAddress(18);
        address USDe_USDT__USDT_VAULT = getVaultAddress(0); // TODO

        {
            // USDe-USDT DEX
            {
                // USDe-USDT Dex
                Dex memory DEX_USDe_USDT = Dex({
                    dex: USDe_USDT_DEX,
                    tokenA: USDe_ADDRESS,
                    tokenB: USDT_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_USDe_USDT); // Smart Collateral

                DEX_FACTORY.setDexAuth(USDe_USDT_DEX, TEAM_MULTISIG, true);
            }
        }

        {
            // [TYPE 2] sUSDe-USDT<>USDT | smart collateral & debt
            Vault memory VAULT_USDe_USDT = Vault({
                vault: USDe_USDT__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_USDe_USDT); // TYPE_2 => 0 // TODO

            VAULT_FACTORY.setVaultAuth(
                USDe_USDT__USDT_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 3: Set initial limits for eBTC-cbBTC dex and eBTC-cbBTC | WBTC T2 vault
    function action3() internal {
        address eBTC_cbBTC_DEX = getDexAddress(16);
        address eBTC_cbBTC__WBTC_VAULT = getVaultAddress(0); // TODO

        {
            // eBTC-cbBTC DEX
            {
                // eBTC-cbBTC Dex
                Dex memory DEX_eBTC_cbBTC = Dex({
                    dex: eBTC_cbBTC_DEX,
                    tokenA: eBTC_ADDRESS,
                    tokenB: cbBTC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_eBTC_cbBTC); // Smart Collateral

                DEX_FACTORY.setDexAuth(eBTC_cbBTC_DEX, TEAM_MULTISIG, true);
            }
        }

        {
            // [TYPE 2] eBTC-cbBTC<>WBTC | smart collateral & debt
            Vault memory VAULT_eBTC_cbBTC = Vault({
                vault: eBTC_cbBTC__WBTC_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_eBTC_cbBTC); // TYPE_2 => 0 // TODO

            VAULT_FACTORY.setVaultAuth(
                eBTC_cbBTC__WBTC_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 4: Set initial limits for lBTC-cbBTC dex and lBTC-cbBTC | WBTC T2 vault
    function action4() internal {
        address lBTC_cbBTC_DEX = getDexAddress(17);
        address lBTC_cbBTC__WBTC_VAULT = getVaultAddress(0); // TODO

        {
            // lBTC-cbBTC DEX
            {
                // lBTC-cbBTC Dex
                Dex memory DEX_lBTC_cbBTC = Dex({
                    dex: lBTC_cbBTC_DEX,
                    tokenA: lBTC_ADDRESS,
                    tokenB: cbBTC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_lBTC_cbBTC); // Smart Collateral

                DEX_FACTORY.setDexAuth(lBTC_cbBTC_DEX, TEAM_MULTISIG, true);
            }
        }

        {
            // [TYPE 2] lBTC-cbBTC<>WBTC | smart collateral & debt
            Vault memory VAULT_lBTC_cbBTC = Vault({
                vault: lBTC_cbBTC__WBTC_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_lBTC_cbBTC); // TYPE_2 => 0 // TODO

            VAULT_FACTORY.setVaultAuth(
                lBTC_cbBTC__WBTC_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 5: Update USDC-USDT Dex Config
    function action5() internal {
        address USDC_USDT_DEX_ADDRESS = getDexAddress(2);

        {
            // double the limits
            Dex memory DEX_USDC_USDT = Dex({
                dex: USDC_USDT_DEX_ADDRESS,
                tokenA: USDC_ADDRESS,
                tokenB: USDT_ADDRESS,
                smartCollateral: false,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 0, // $0
                baseBorrowLimitInUSD: 10_000_000, // $10M
                maxBorrowLimitInUSD: 40_000_000 // $40M
            });
            setDexLimits(DEX_USDC_USDT); // Smart Debt
        }

        {
            // Update Range
            IFluidDex(USDC_USDT_DEX_ADDRESS).updateRangePercents(
                0.1 * 1e4,
                0.1 * 1e4,
                2 days
            );
        }
    }

    // @notice Action 6: Update wstETH-ETH Dex Config
    function action6() internal {
        address wstETH_ETH_DEX_ADDRESS = getDexAddress(1);

        {
            // double the limits
            Dex memory DEX_wstETH_ETH = Dex({
                dex: wstETH_ETH_DEX_ADDRESS,
                tokenA: wstETH_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 15_000_000, // $15M
                baseBorrowLimitInUSD: 15_000_000, // $15M
                maxBorrowLimitInUSD: 45_000_000 // $45M
            });
            setDexLimits(DEX_wstETH_ETH); // Smart Debt
        }

        {
            // Update Range
            IFluidDex(wstETH_ETH_DEX_ADDRESS).updateRangePercents(
                0.0001 * 1e4,
                0.06 * 1e4,
                1
            );
        }
    }

    /// @notice Action 7: Update vault deployment logics on vault factory
    function action7() internal {
        {
            // Vault T1
            address OLD_DEPLOYMENT_LOGIC = 0x2Cc710218F2e3a82CcC77Cc4B3B93Ee6Ba9451CD;
            address NEW_DEPLOYMENT_LOGIC = 0xF4b87B0A2315534A8233724b87f2a8E3197ad649;

            VAULT_FACTORY.setVaultDeploymentLogic(OLD_DEPLOYMENT_LOGIC, false);
            VAULT_FACTORY.setVaultDeploymentLogic(NEW_DEPLOYMENT_LOGIC, true);
        }

        {
            // Vault T2
            address OLD_DEPLOYMENT_LOGIC = 0xD4d748356D1C82A5565a15a1670D13FB505b018E;
            address NEW_DEPLOYMENT_LOGIC = 0xf92b954D3B2F6497B580D799Bf0907332AF1f63B;

            VAULT_FACTORY.setVaultDeploymentLogic(OLD_DEPLOYMENT_LOGIC, false);
            VAULT_FACTORY.setVaultDeploymentLogic(NEW_DEPLOYMENT_LOGIC, true);
        }

        {
            // Vault T3
            address OLD_DEPLOYMENT_LOGIC = 0x84b2A41339ef51FFAc89Ffe69cAd53CD92b82A28;
            address NEW_DEPLOYMENT_LOGIC = 0xbc9c8528c66D1910CFb6Bde2a8f1C2F1D38026c7;

            VAULT_FACTORY.setVaultDeploymentLogic(OLD_DEPLOYMENT_LOGIC, false);
            VAULT_FACTORY.setVaultDeploymentLogic(NEW_DEPLOYMENT_LOGIC, true);
        }

        {
            // Vault T4
            address OLD_DEPLOYMENT_LOGIC = 0x13472F00A43B59b644B301fEd48651c0C889bdB4;
            address NEW_DEPLOYMENT_LOGIC = 0xC292c87F3116CBbfb2186d4594Dc48d55fCa6e34;

            VAULT_FACTORY.setVaultDeploymentLogic(OLD_DEPLOYMENT_LOGIC, false);
            VAULT_FACTORY.setVaultDeploymentLogic(NEW_DEPLOYMENT_LOGIC, true);
        }
    }

    // @notice Action 8: Remove sUSDe handlers
    function action8() internal {
        {
            // USDC based vault
            address USDC_VAULT_HANDLER = 0xf4f24CDD9A9929Ce262735253BADB03F959D208f;
            address sUSDe_VAULT_ADDRESS = getVaultAddress(27); // sUSDe<>USDC
            address OLD_sUSDe_VAULT_ADDRESS = getVaultAddress(7); // Old sUSDe<>USDC
            address USDe_VAULT_ADDRESS = getVaultAddress(66); // USDe<>USDC

            VAULT_FACTORY.setVaultAuth(
                sUSDe_VAULT_ADDRESS,
                USDC_VAULT_HANDLER,
                false
            );
            VAULT_FACTORY.setVaultAuth(
                OLD_sUSDe_VAULT_ADDRESS,
                USDC_VAULT_HANDLER,
                false
            );
            VAULT_FACTORY.setVaultAuth(
                USDe_VAULT_ADDRESS,
                USDC_VAULT_HANDLER,
                false
            );
        }

        {
            // USDT based vault
            address USDT_VAULT_HANDLER = 0xca91be2077Aad98A8B7ce82a665024c2Fd7e74Be;
            address sUSDe_VAULT_ADDRESS = getVaultAddress(28); // sUSDe<>USDT
            address OLD_sUSDe_VAULT_ADDRESS = getVaultAddress(8); // Old sUSDe<>USDT
            address USDe_VAULT_ADDRESS = getVaultAddress(67); // USDe<>USDT

            VAULT_FACTORY.setVaultAuth(
                sUSDe_VAULT_ADDRESS,
                USDT_VAULT_HANDLER,
                false
            );
            VAULT_FACTORY.setVaultAuth(
                OLD_sUSDe_VAULT_ADDRESS,
                USDT_VAULT_HANDLER,
                false
            );
            VAULT_FACTORY.setVaultAuth(
                USDe_VAULT_ADDRESS,
                USDT_VAULT_HANDLER,
                false
            );
        }

        {
            // GHO based vault
            address GHO_VAULT_HANDLER = 0x4acF39b8A63C744ce37594234eBebF5F99DfC710;
            address sUSDe_VAULT_ADDRESS = getVaultAddress(56); // sUSDe<>GHO
            address USDe_VAULT_ADDRESS = getVaultAddress(68); // USDe<>GHO

            VAULT_FACTORY.setVaultAuth(
                sUSDe_VAULT_ADDRESS,
                GHO_VAULT_HANDLER,
                false
            );
            VAULT_FACTORY.setVaultAuth(
                USDe_VAULT_ADDRESS,
                GHO_VAULT_HANDLER,
                false
            );
        }
    }

    /**
     * |
     * |     Proposal Payload Helpers      |
     * |__________________________________
     */
    struct Dex {
        address dex;
        address tokenA;
        address tokenB;
        bool smartCollateral;
        bool smartDebt;
        uint256 baseWithdrawalLimitInUSD;
        uint256 baseBorrowLimitInUSD;
        uint256 maxBorrowLimitInUSD;
    }

    enum TYPE {
        TYPE_1,
        TYPE_2,
        TYPE_3,
        TYPE_4
    }

    struct Vault {
        address vault;
        TYPE vaultType;
        address supplyToken;
        address borrowToken;
        uint256 baseWithdrawalLimitInUSD;
        uint256 baseBorrowLimitInUSD;
        uint256 maxBorrowLimitInUSD;
    }

    function setDexLimits(Dex memory dex_) internal {
        // Smart Collateral
        if (dex_.smartCollateral) {
            SupplyProtocolConfig memory protocolConfigTokenA_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenA,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseWithdrawalLimitInUSD: dex_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfigTokenA_);

            SupplyProtocolConfig memory protocolConfigTokenB_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenB,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseWithdrawalLimitInUSD: dex_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfigTokenB_);
        }

        // Smart Debt
        if (dex_.smartDebt) {
            BorrowProtocolConfig memory protocolConfigTokenA_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenA,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseBorrowLimitInUSD: dex_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: dex_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfigTokenA_);

            BorrowProtocolConfig memory protocolConfigTokenB_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenB,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseBorrowLimitInUSD: dex_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: dex_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfigTokenB_);
        }
    }

    function setVaultLimits(Vault memory vault_) internal {
        if (
            vault_.vaultType == TYPE.TYPE_3 || vault_.vaultType == TYPE.TYPE_1
        ) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimitInUSD: vault_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        if (
            vault_.vaultType == TYPE.TYPE_2 || vault_.vaultType == TYPE.TYPE_1
        ) {
            BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
                protocol: vault_.vault,
                borrowToken: vault_.borrowToken,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours, // 12 hours
                baseBorrowLimitInUSD: vault_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: vault_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfig_);
        }
    }

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 3_330 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 3_950 * 1e2;
    uint256 public constant weETH_USD_PRICE = 3_550 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 3_850 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 3_750 * 1e2;
    uint256 public constant mETH_USD_PRICE = 3_850 * 1e2;

    uint256 public constant BTC_USD_PRICE = 99_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.15 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.02 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 6 * 1e2;

    function getRawAmount(
        address token,
        uint256 amount,
        uint256 amountInUSD,
        bool isSupply
    ) public view override returns (uint256) {
        if (amount > 0 && amountInUSD > 0) {
            revert("both usd and amount are not zero");
        }
        uint256 exchangePriceAndConfig_ = LIQUIDITY.readFromStorage(
            LiquiditySlotsLink.calculateMappingStorageSlot(
                LiquiditySlotsLink.LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT,
                token
            )
        );

        (
            uint256 supplyExchangePrice,
            uint256 borrowExchangePrice
        ) = LiquidityCalcs.calcExchangePrices(exchangePriceAndConfig_);

        uint256 usdPrice = 0;
        uint256 decimals = 18;
        if (token == ETH_ADDRESS) {
            usdPrice = ETH_USD_PRICE;
            decimals = 18;
        } else if (token == wstETH_ADDRESS) {
            usdPrice = wstETH_USD_PRICE;
            decimals = 18;
        } else if (token == weETH_ADDRESS) {
            usdPrice = weETH_USD_PRICE;
            decimals = 18;
        } else if (token == rsETH_ADDRESS) {
            usdPrice = rsETH_USD_PRICE;
            decimals = 18;
        } else if (token == weETHs_ADDRESS) {
            usdPrice = weETHs_USD_PRICE;
            decimals = 18;
        } else if (token == mETH_ADDRESS) {
            usdPrice = mETH_USD_PRICE;
            decimals = 18;
        } else if (
            token == cbBTC_ADDRESS ||
            token == WBTC_ADDRESS ||
            token == eBTC_ADDRESS ||
            token == lBTC_ADDRESS
        ) {
            usdPrice = BTC_USD_PRICE;
            decimals = 8;
        } else if (token == tBTC_ADDRESS) {
            usdPrice = BTC_USD_PRICE;
            decimals = 18;
        } else if (token == USDC_ADDRESS || token == USDT_ADDRESS) {
            usdPrice = STABLE_USD_PRICE;
            decimals = 6;
        } else if (token == sUSDe_ADDRESS) {
            usdPrice = sUSDe_USD_PRICE;
            decimals = 18;
        } else if (token == sUSDs_ADDRESS) {
            usdPrice = sUSDs_USD_PRICE;
            decimals = 18;
        } else if (token == GHO_ADDRESS || token == USDe_ADDRESS) {
            usdPrice = STABLE_USD_PRICE;
            decimals = 18;
        } else if (token == INST_ADDRESS) {
            usdPrice = FLUID_USD_PRICE;
            decimals = 18;
        } else {
            revert("not-found");
        }

        uint256 exchangePrice = isSupply
            ? supplyExchangePrice
            : borrowExchangePrice;

        if (amount > 0) {
            return (amount * 1e12) / exchangePrice;
        } else {
            return
                (amountInUSD * 1e12 * (10 ** decimals)) /
                ((usdPrice * exchangePrice) / 1e2);
        }
    }
}
