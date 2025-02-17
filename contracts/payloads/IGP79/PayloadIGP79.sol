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

contract PayloadIGP79 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 79;

    bool public skipAction1;
    bool public skipAction2;
    bool public skipAction3;
    bool public skipAction4;
    bool public skipAction5;
    bool public skipAction6;
    bool public skipAction7;
    bool public skipAction8;
    bool public skipAction9;
    bool public skipAction10;
    bool public isExecutable;
    bool public skipCbbtcWbtcCenterPriceUpdate;

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
        if (!PayloadIGP79(ADDRESS_THIS).isExecutable()) {
            revert("IGP-79 Execution not executable");
        }

        require(address(this) == address(TIMELOCK), "not-valid-caller");

        // Action 1: Set launch limits for sUSDs based vaults
        action1();

        // Action 2: Set launch limits for sUSDe-USDT dex and sUSDe-USDT<>USDT T2 vault
        action2();

        // Action 3: Set launch limits for USDe-USDT dex and USDe-USDT<>USDT T2 vault
        action3();

        // Action 4: Set launch limits for tBTC<>USDC, tBTC<>USDT, tBTC<>GHO vaults
        action4();

        // Action 5: Set launch limits for eBTC-cbBTC DEX and eBTC-cbBTC<>WBTC T2 and eBTC<>wBTC T1 vaults
        action5();

        // Action 6: Set launch limits for lBTC-cbBTC DEX and lBTC-cbBTC<>WBTC T2 vault
        action6();

        // Action 7: Set launch limits for deUSD-USDC DEX
        action7();

        // Action 8: Update wbBTC<>cbBTC DEX configs
        action8();

        // Action 9: Collect revenue
        action9();

        // Action 10: Increase the ETH-USDC DEX limits
        action10();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Team Multisig Actions      |
     * |__________________________________
     */
    function setState(
        bool skipAction1_,
        bool skipAction2_,
        bool skipAction3_,
        bool skipAction4_,
        bool skipAction5_,
        bool skipAction6_,
        bool skipAction7_,
        bool skipAction8_,
        bool skipAction9_,
        bool skipAction10_,
        bool isExecutable_,
        bool skipCbbtcWbtcCenterPriceUpdate_
    ) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }

        skipAction1 = skipAction1_;
        skipAction2 = skipAction2_;
        skipAction3 = skipAction3_;
        skipAction4 = skipAction4_;
        skipAction5 = skipAction5_;
        skipAction6 = skipAction6_;
        skipAction7 = skipAction7_;
        skipAction8 = skipAction8_;
        skipAction9 = skipAction9_;
        skipAction10 = skipAction10_;
        isExecutable = isExecutable_;
        skipCbbtcWbtcCenterPriceUpdate = skipCbbtcWbtcCenterPriceUpdate_;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Set launch limits for sUSDs based vaults
    function action1() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction1()) return;

        {
            address ETH_sUSDs_VAULT = getVaultAddress(84);

            // [TYPE 1] ETH<>sUSDs | collateral & debt
            Vault memory VAULT_ETH_sUSDs = Vault({
                vault: ETH_sUSDs_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: ETH_ADDRESS,
                borrowToken: sUSDs_ADDRESS,
                baseWithdrawalLimitInUSD: 20_000_000, // $20M
                baseBorrowLimitInUSD: 20_000_000, // $20M
                maxBorrowLimitInUSD: 100_000_000 // $100M
            });

            setVaultLimits(VAULT_ETH_sUSDs); // TYPE_1 => 84

            VAULT_FACTORY.setVaultAuth(ETH_sUSDs_VAULT, TEAM_MULTISIG, false);
        }

        {
            address wstETH_sUSDs_VAULT = getVaultAddress(85);

            // [TYPE 1] wstETH<>sUSDs | collateral & debt
            Vault memory VAULT_wstETH_sUSDs = Vault({
                vault: wstETH_sUSDs_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: wstETH_ADDRESS,
                borrowToken: sUSDs_ADDRESS,
                baseWithdrawalLimitInUSD: 20_000_000, // $20M
                baseBorrowLimitInUSD: 20_000_000, // $20M
                maxBorrowLimitInUSD: 100_000_000 // $100M
            });

            setVaultLimits(VAULT_wstETH_sUSDs); // TYPE_1 => 85

            VAULT_FACTORY.setVaultAuth(
                wstETH_sUSDs_VAULT,
                TEAM_MULTISIG,
                false
            );
        }

        {
            address cbBTC_sUSDs_VAULT = getVaultAddress(86);

            // [TYPE 1] cbBTC<>sUSDs | collateral & debt
            Vault memory VAULT_cbBTC_sUSDs = Vault({
                vault: cbBTC_sUSDs_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: cbBTC_ADDRESS,
                borrowToken: sUSDs_ADDRESS,
                baseWithdrawalLimitInUSD: 20_000_000, // $20M
                baseBorrowLimitInUSD: 20_000_000, // $20M
                maxBorrowLimitInUSD: 100_000_000 // $100M
            });

            setVaultLimits(VAULT_cbBTC_sUSDs); // TYPE_1 => 86

            VAULT_FACTORY.setVaultAuth(cbBTC_sUSDs_VAULT, TEAM_MULTISIG, false);
        }

        {
            address weETH_sUSDs_VAULT = getVaultAddress(91);

            // [TYPE 1] weETH<>sUSDs | collateral & debt
            Vault memory VAULT_weETH_sUSDs = Vault({
                vault: weETH_sUSDs_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: weETH_ADDRESS,
                borrowToken: sUSDs_ADDRESS,
                baseWithdrawalLimitInUSD: 20_000_000, // $20M
                baseBorrowLimitInUSD: 20_000_000, // $20M
                maxBorrowLimitInUSD: 100_000_000 // $100M
            });

            setVaultLimits(VAULT_weETH_sUSDs); // TYPE_1 => 91

            VAULT_FACTORY.setVaultAuth(weETH_sUSDs_VAULT, TEAM_MULTISIG, false);
        }
    }

    // @notice Action 2: Set launch limits for sUSDe-USDT dex and sUSDe-USDT<>USDT T2 vault
    function action2() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction2()) return;

        address sUSDe_USDT_DEX = getDexAddress(15);
        address sUSDe_USDT__USDT_VAULT = getVaultAddress(92);
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
                    baseWithdrawalLimitInUSD: 15_000_000, // $15M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_sUSDe_USDT); // Smart Collateral

                DEX_FACTORY.setDexAuth(sUSDe_USDT_DEX, TEAM_MULTISIG, false);
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
                baseBorrowLimitInUSD: 15_000_000, // $15M
                maxBorrowLimitInUSD: 30_000_000 // $30M
            });

            setVaultLimits(VAULT_sUSDe_USDT); // TYPE_2 => 92

            VAULT_FACTORY.setVaultAuth(
                sUSDe_USDT__USDT_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 3: Set launch limits for USDe-USDT dex and USDe-USDT<>USDT T2 vault
    function action3() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction3()) return;

        address USDe_USDT_DEX = getDexAddress(18);
        address USDe_USDT__USDT_VAULT = getVaultAddress(93);

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
                    baseWithdrawalLimitInUSD: 15_000_000, // $15M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_USDe_USDT); // Smart Collateral

                DEX_FACTORY.setDexAuth(USDe_USDT_DEX, TEAM_MULTISIG, false);
            }
        }

        {
            // [TYPE 2] USDe-USDT<>USDT | smart collateral & debt
            Vault memory VAULT_USDe_USDT = Vault({
                vault: USDe_USDT__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 15_000_000, // $15M
                maxBorrowLimitInUSD: 30_000_000 // $30M
            });

            setVaultLimits(VAULT_USDe_USDT); // TYPE_2 => 93

            VAULT_FACTORY.setVaultAuth(
                USDe_USDT__USDT_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 4: Set launch limits for tBTC<>USDC, tBTC<>USDT, tBTC<>GHO vaults
    function action4() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction4()) return;

        {
            address tBTC_USDC_VAULT = getVaultAddress(88);

            // [TYPE 1] tBTC<>USDC | collateral & debt
            Vault memory VAULT_tBTC_USDC = Vault({
                vault: tBTC_USDC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: tBTC_ADDRESS,
                borrowToken: USDC_ADDRESS,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_tBTC_USDC); // TYPE_1 => 88

            VAULT_FACTORY.setVaultAuth(tBTC_USDC_VAULT, TEAM_MULTISIG, false);
        }

        {
            address tBTC_USDT_VAULT = getVaultAddress(89);

            // [TYPE 1] tBTC<>USDT | collateral & debt
            Vault memory VAULT_tBTC_USDT = Vault({
                vault: tBTC_USDT_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: tBTC_ADDRESS,
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_tBTC_USDT); // TYPE_1 => 89

            VAULT_FACTORY.setVaultAuth(tBTC_USDT_VAULT, TEAM_MULTISIG, false);
        }

        {
            address tBTC_GHO_VAULT = getVaultAddress(90);

            // [TYPE 1] tBTC<>GHO | collateral & debt
            Vault memory VAULT_tBTC_GHO = Vault({
                vault: tBTC_GHO_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: tBTC_ADDRESS,
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_tBTC_GHO); // TYPE_1 => 90

            VAULT_FACTORY.setVaultAuth(tBTC_GHO_VAULT, TEAM_MULTISIG, false);
        }
    }

    // @notice Action 5: Set launch limits for eBTC-cbBTC DEX and eBTC-cbBTC<>WBTC T2 and eBTC<>wBTC T1 vaults
    function action5() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction5()) return;

        address eBTC_cbBTC_DEX = getDexAddress(16);
        address eBTC_cbBTC__WBTC_VAULT = getVaultAddress(96);
        address eBTC__wBTC_VAULT = getVaultAddress(94);
        address eBTC__cbBTC_VAULT = getVaultAddress(95);

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
                    baseWithdrawalLimitInUSD: 20_000_000, // $20M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_eBTC_cbBTC); // Smart Collateral

                DEX_FACTORY.setDexAuth(eBTC_cbBTC_DEX, TEAM_MULTISIG, false);
            }
        }

        {
            // [TYPE 2] eBTC-cbBTC<>WBTC | smart collateral & normal debt
            Vault memory VAULT_eBTC_cbBTC = Vault({
                vault: eBTC_cbBTC__WBTC_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });

            setVaultLimits(VAULT_eBTC_cbBTC); // TYPE_2 => 96

            VAULT_FACTORY.setVaultAuth(
                eBTC_cbBTC__WBTC_VAULT,
                TEAM_MULTISIG,
                false
            );
        }

        // {
        //     // [TYPE 1] eBTC<>cbBTC | normal collateral & normal debt
        //     Vault memory VAULT_eBTC_cbBTC = Vault({
        //         vault: eBTC__cbBTC_VAULT,
        //         vaultType: TYPE.TYPE_1,
        //         supplyToken: eBTC_ADDRESS,
        //         borrowToken: cbBTC_ADDRESS,
        //         baseWithdrawalLimitInUSD: 5_000_000, // $5M
        //         baseBorrowLimitInUSD: 5_000_000, // $5M
        //         maxBorrowLimitInUSD: 7_500_000 // $7.5M
        //     });

        //     setVaultLimits(VAULT_eBTC_cbBTC); // TYPE_1 => 95

        //     VAULT_FACTORY.setVaultAuth(eBTC__cbBTC_VAULT, TEAM_MULTISIG, false);
        // }

        {
            // [TYPE 1] eBTC<>wBTC | normal collateral & normal debt
            Vault memory VAULT_eBTC_wBTC = Vault({
                vault: eBTC__wBTC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: eBTC_ADDRESS,
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });

            setVaultLimits(VAULT_eBTC_wBTC); // TYPE_1 => 94

            VAULT_FACTORY.setVaultAuth(eBTC__wBTC_VAULT, TEAM_MULTISIG, false);
        }
    }

    // @notice Action 6: Set launch limits for lBTC-cbBTC DEX and lBTC-cbBTC<>WBTC T2 vault
    function action6() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction6()) return;

        address lBTC_cbBTC_DEX = getDexAddress(17);
        address lBTC_cbBTC__WBTC_VAULT = getVaultAddress(97);

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
                    baseWithdrawalLimitInUSD: 20_000_000, // $20M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_lBTC_cbBTC); // Smart Collateral

                DEX_FACTORY.setDexAuth(lBTC_cbBTC_DEX, TEAM_MULTISIG, false);
            }
        }

        {
            // [TYPE 2] lBTC-cbBTC<>WBTC | smart collateral & normal debt
            Vault memory VAULT_lBTC_cbBTC_wBTC = Vault({
                vault: lBTC_cbBTC__WBTC_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });

            setVaultLimits(VAULT_lBTC_cbBTC_wBTC); // TYPE_2 => 97

            VAULT_FACTORY.setVaultAuth(
                lBTC_cbBTC__WBTC_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 7: Set launch limits for deUSD-USDC DEX
    function action7() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction7()) return;

        address deUSD_USDC_DEX = getDexAddress(19);

        {
            // deUSD-USDC DEX
            {
                // deUSD-USDC Dex
                Dex memory DEX_deUSD_USDC = Dex({
                    dex: deUSD_USDC_DEX,
                    tokenA: deUSD_ADDRESS,
                    tokenB: USDC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000_000, // $10M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_deUSD_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(deUSD_USDC_DEX, TEAM_MULTISIG, true);
            }
        }
    }

    // @notice Action 8: Update wbBTC<>cbBTC DEX configs
    function action8() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction8()) return;

        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        // updates the upper and lower range +-0.2%
        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateRangePercents(
            0.2 * 1e4,
            0.2 * 1e4,
            2 days
        );

        if (!PayloadIGP79(ADDRESS_THIS).skipCbbtcWbtcCenterPriceUpdate()) {
            // update min/max center price limits to 0.2%
            uint256 minCenterPrice_ = (998 * 1e27) / 1000;
            uint256 maxCenterPrice_ = uint256(1e27 * 1000) / 998;
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateCenterPriceLimits(
                maxCenterPrice_,
                minCenterPrice_
            );
        }

    }

    // @notice Action 9: Collect revenue
    function action9() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction9()) return;

        address[] memory tokens = new address[](7);

        tokens[0] = ETH_ADDRESS;
        tokens[1] = wstETH_ADDRESS;
        tokens[2] = USDC_ADDRESS;
        tokens[3] = USDT_ADDRESS;
        tokens[4] = GHO_ADDRESS;
        tokens[5] = WBTC_ADDRESS;
        tokens[6] = cbBTC_ADDRESS;

        LIQUIDITY.collectRevenue(tokens);
    }

    // @notice Action 10: Increase ETH-USDC DEX limits
    function action10() internal {
        if (PayloadIGP79(ADDRESS_THIS).skipAction10()) return;

        address ETH_USDC_DEX_ADDRESS = getDexAddress(12);
        address ETH_USDC_VAULT_ADDRESS = getVaultAddress(77);

        {
            // Double the ETH-USDC Dex Limits
            Dex memory DEX_ETH_USDC = Dex({
                dex: ETH_USDC_DEX_ADDRESS,
                tokenA: ETH_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 30_000_000, // $30M
                baseBorrowLimitInUSD: 24_000_000, // $24M
                maxBorrowLimitInUSD: 60_000_000 // $60M
            });
            setDexLimits(DEX_ETH_USDC); // Smart Collateral and Smart Debt
        }

        {
            // Double Max Supply Shares
            IFluidDex(ETH_USDC_DEX_ADDRESS).updateMaxSupplyShares(
                30_000_000 * 1e18
            ); // 30M
        }

        {
            // Double Max Borrow Shares
            IFluidDex(ETH_USDC_DEX_ADDRESS).updateMaxBorrowShares(
                20_000_000 * 1e18
            ); // 20M
        }

        {
            // Update ETH-USDC vault supply shares limit
            IFluidAdminDex.UserSupplyConfig[]
                memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: ETH_USDC_VAULT_ADDRESS,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimit: 10_000_000 * 1e18 // 10M shares
            });

            IFluidDex(ETH_USDC_DEX_ADDRESS).updateUserSupplyConfigs(config_);
        }

        {
            // Update ETH-USDC vault borrow shares limit
            IFluidAdminDex.UserBorrowConfig[]
                memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
            config_[0] = IFluidAdminDex.UserBorrowConfig({
                user: ETH_USDC_VAULT_ADDRESS,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours, // 12 hours
                baseDebtCeiling: 10_000_000 * 1e18, // 10M shares // 2x
                maxDebtCeiling: 20_000_000 * 1e18 // 20M shares // 2x
            });

            IFluidDex(ETH_USDC_DEX_ADDRESS).updateUserBorrowConfigs(config_);
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
    uint256 public constant weETH_USD_PRICE = 3_500 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 3_850 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 3_750 * 1e2;
    uint256 public constant mETH_USD_PRICE = 3_850 * 1e2;

    uint256 public constant BTC_USD_PRICE = 106_000 * 1e2;

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
        } else if (
            token == GHO_ADDRESS ||
            token == USDe_ADDRESS ||
            token == deUSD_ADDRESS
        ) {
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
