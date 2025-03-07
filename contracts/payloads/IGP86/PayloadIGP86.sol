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

import {ISmartLendingAdmin} from "../common/interfaces/ISmartLending.sol";
import {ISmartLendingFactory} from "../common/interfaces/ISmartLendingFactory.sol";

import {ICodeReader} from "../common/interfaces/ICodeReader.sol";

import {IDSAV2} from "../common/interfaces/IDSA.sol";
import {IERC20} from "../common/interfaces/IERC20.sol";
import {IProxy} from "../common/interfaces/IProxy.sol";
import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";
import {PayloadIGPMain} from "../common/main.sol";

contract PayloadIGP86 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 86;

    function execute() public virtual override {
        super.execute();

        // Action 1: Reset launch limits for ezETH-ETH DEX and ezETH<>wstETH T1 & ezETH-ETH<>wstETH T2 vaults
        action1();

        // Action 2: Set launch limits for cbBTC-ETH DEX T4 vault
        action2();

        // Action 3: Update base limits for all DEXes according to their caps
        action3();

        // Action 4: Set creation code for SmartLendingFactory
        action4();

        // Action 5: Transfer 500k FLUID to Team Multisig
        action5();

        // Action 6: Delist mETH vaults
        action6();
    }

    function verifyProposal() public view override {}

    function _PROPOSAL_ID() internal view override returns (uint256) {
        return PROPOSAL_ID;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Reset launch limits for ezETH-ETH DEX and ezETH<>wstETH T1 & ezETH-ETH<>wstETH T2 vaults
    function action1() internal isActionSkippable(1) {
        {
            address ezETH_ETH_DEX = getDexAddress(21);
            // ezETH-ETH DEX
            {
                // ezETH-ETH Dex
                Dex memory DEX_ezETH_ETH = Dex({
                    dex: ezETH_ETH_DEX,
                    tokenA: ezETH_ADDRESS,
                    tokenB: ETH_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_ezETH_ETH); // Smart Collateral

                DEX_FACTORY.setDexAuth(ezETH_ETH_DEX, TEAM_MULTISIG, false);
            }
        }

        {
            address ezETH__wstETH_VAULT = getVaultAddress(103);

            // [TYPE 1] ezETH<>wstETH | normal collateral & normal debt
            Vault memory VAULT_ezETH_wstETH = Vault({
                vault: ezETH__wstETH_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: ezETH_ADDRESS,
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000_000, // $10M
                baseBorrowLimitInUSD: 10_000_000, // $10M
                maxBorrowLimitInUSD: 20_000_000 // $20M
            });

            setVaultLimits(VAULT_ezETH_wstETH); // TYPE_1 => 103

            VAULT_FACTORY.setVaultAuth(
                ezETH__wstETH_VAULT,
                TEAM_MULTISIG,
                false
            );
        }

        {
            address ezETH_ETH__wstETH_VAULT = getVaultAddress(104);

            // [TYPE 2] ezETH-ETH<>wstETH | smart collateral & normal debt
            Vault memory VAULT_ezETH_ETH_wstETH = Vault({
                vault: ezETH_ETH__wstETH_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });

            setVaultLimits(VAULT_ezETH_ETH_wstETH); // TYPE_2 => 104

            VAULT_FACTORY.setVaultAuth(
                ezETH_ETH__wstETH_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 2: Set launch limits for cbBTC-ETH DEX T4 vault
    function action2() internal isActionSkippable(2) {
        address cbBTC_ETH_DEX_ADDRESS = getDexAddress(26);

        {
            // dust limits
            Dex memory DEX_cbBTC_ETH = Dex({
                dex: cbBTC_ETH_DEX_ADDRESS,
                tokenA: cbBTC_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 15_000_000, // $15M
                baseBorrowLimitInUSD: 15_000_000, // $15M
                maxBorrowLimitInUSD: 30_000_000 // $30M
            });
            setDexLimits(DEX_cbBTC_ETH); // Smart Collateral & Smart Debt

            DEX_FACTORY.setDexAuth(
                cbBTC_ETH_DEX_ADDRESS, 
                TEAM_MULTISIG, 
                false
            );
        }

        {
            address cbBTC_ETH__cbBTC_ETH_VAULT_ADRESS = getVaultAddress(106);

            // Set team multisig as vault auth for cbBTC-ETH T4 Vault
            VAULT_FACTORY.setVaultAuth(
                cbBTC_ETH__cbBTC_ETH_VAULT_ADRESS,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 3: Update base limits for all DEXes according to their caps
    function action3() internal isActionSkippable(3) {
        // Update each DEX individually with their specific USD caps
        updateDexBaseLimits(1, 8_000, 7_200);    // wstETH-ETH DEX (Smart Collateral & Smart Debt)
        updateDexBaseLimits(2, 0, 25_000_000);             // USDC-USDT DEX (Smart Debt only)
        updateDexBaseLimits(3, 175, 125);             // cbBTC-WBTC DEX (Smart Collateral & Smart Debt)
        updateDexBaseLimits(4, 5_000_000, 4_000_000);  // GHO-USDC DEX (Smart Collateral & Smart Debt)
//        updateDexBaseLimits(5, 0, 0);                     // Skip DEX 5
//        updateDexBaseLimits(6, 0, 0);                     // Skip DEX 6
//        updateDexBaseLimits(7, 0, 0);                     // Skip DEX 7
//        updateDexBaseLimits(8, 0, 0);                     // Skip DEX 8
        updateDexBaseLimits(9, 9_000, 0);    // weETH-ETH DEX (Smart Collateral Only)
//        updateDexBaseLimits(10, 0, 0);                    // Skip DEX 10
        updateDexBaseLimits(11, 1_415_000, 0); // FLUID-ETH DEX (-)
        updateDexBaseLimits(12, 30_000_000, 20_000_000); // USDC-ETH DEX (Smart Collateral & Smart Debt)
        updateDexBaseLimits(13, 3_200, 0); // rsETH-ETH DEX (Smart Collateral Only)
        updateDexBaseLimits(14, 1_600, 0); // weETHs-ETH DEX (Smart Collateral Only)
        updateDexBaseLimits(15, 25_000_000, 0); // sUSDe-USDT DEX (Smart Collateral Only)
        updateDexBaseLimits(16, 110, 0); // eBTC-cbBTC DEX (Smart Collateral Only)
        updateDexBaseLimits(17, 110, 0); // LBTC-cbBTC DEX (Smart Collateral Only)
        updateDexBaseLimits(18, 10_000_000, 0); // USDe-USDT DEX (Smart Collateral Only)
        updateDexBaseLimits(19, 7_500_000, 0); // deUSD-USDC DEX (Smart Collateral Only)
        updateDexBaseLimits(20, 7_500_000, 0); // USR-USDC DEX (Smart Collateral Only)
//        updateDexBaseLimits(21, 0, 0);                    // Skip DEX 21
        updateDexBaseLimits(22, 14_000_000, 10_000_000); // cbBTC-USDT DEX (Smart Collateral & Smart Debt)
        updateDexBaseLimits(23, 7_500_000, 0);  // USD0-USDC DEX (Smart Collateral Only)
        updateDexBaseLimits(24, 7_500_000, 0); // fxUSD-USDC DEX (Smart Collateral Only)
//        updateDexBaseLimits(25, 0, 0);                    // Skip DEX 25
//        updateDexBaseLimits(26, 0, 0);                    // Skip DEX 26
    }

    // @notice Action 4: Set creation code for SmartLendingFactory
    function action4() internal isActionSkippable(4) {
        address SMART_LENDING_FACTORY = 0xe57227C7d5900165344b190fc7aa580bceb53B9B;
        address SSTORE2_POINTER = 0x99a516222A64c7F5FFdC760a3bc28905140e666D;
        address SSTORE2_DEPLOYER = 0x94a58428980291Af59adfe96844FAff088737e8F;

        // Get the creation code directly from the pointer
        bytes memory creationCode = ICodeReader(SSTORE2_DEPLOYER).readCode(SSTORE2_POINTER);

        // Set the creation code in the factory
        ISmartLendingFactory(SMART_LENDING_FACTORY).setCreationCode(creationCode);
    }

    // @notice Action 5: Transfer 500k FLUID to Team Multisig
    function action5() internal isActionSkippable(5){
        string[] memory targets = new string[](1);
        bytes[] memory encodedSpells = new bytes[](1);

        string
            memory withdrawSignature = "withdraw(address,uint256,address,uint256,uint256)";

        // Spell 1: Transfer INST to Team Multisig
        {
            uint256 FLUID_AMOUNT = 500_000 * 1e18; // 500k FLUID
            targets[0] = "BASIC-A";
            encodedSpells[0] = abi.encodeWithSignature(
                withdrawSignature,
                FLUID_ADDRESS,
                FLUID_AMOUNT,
                TEAM_MULTISIG,
                0,
                0
            );
        }

        IDSAV2(TREASURY).cast(targets, encodedSpells, address(this));
    }

    // @notice Action 6: Delist mETH vaults
    function action6() internal isActionSkippable(6){
        // Delist mETH<>USDC vault
        {
            address vault_meth_usdc = getVaultAddress(81);
            // Pause supply and borrow limits
            setSupplyProtocolLimitsPaused(vault_meth_usdc, mETH_ADDRESS);
            setBorrowProtocolLimitsPaused(vault_meth_usdc, USDC_ADDRESS);
            // Pause user operations for both tokens
            address[] memory supplyTokens = new address[](1);
            address[] memory borrowTokens = new address[](1);
            supplyTokens[0] = mETH_ADDRESS;
            borrowTokens[0] = USDC_ADDRESS;
            LIQUIDITY.pauseUser(vault_meth_usdc, supplyTokens, borrowTokens);
        }

        // Delist mETH<>USDT vault
        {
            address vault_meth_usdt = getVaultAddress(82);
            // Pause supply and borrow limits
            setSupplyProtocolLimitsPaused(vault_meth_usdt, mETH_ADDRESS);
            setBorrowProtocolLimitsPaused(vault_meth_usdt, USDT_ADDRESS);
            // Pause user operations for both tokens
            address[] memory supplyTokens = new address[](1);
            address[] memory borrowTokens = new address[](1);
            supplyTokens[0] = mETH_ADDRESS;
            borrowTokens[0] = USDT_ADDRESS;
            LIQUIDITY.pauseUser(vault_meth_usdt, supplyTokens, borrowTokens);
        }

        // Delist mETH<>GHO vault
        {
            address vault_meth_gho = getVaultAddress(83);
            // Pause supply and borrow limits
            setSupplyProtocolLimitsPaused(vault_meth_gho, mETH_ADDRESS);
            setBorrowProtocolLimitsPaused(vault_meth_gho, GHO_ADDRESS);
            // Pause user operations for both tokens
            address[] memory supplyTokens = new address[](1);
            address[] memory borrowTokens = new address[](1);
            supplyTokens[0] = mETH_ADDRESS;
            borrowTokens[0] = GHO_ADDRESS;
            LIQUIDITY.pauseUser(vault_meth_gho, supplyTokens, borrowTokens);
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
            SupplyProtocolConfig
                memory protocolConfigTokenA_ = SupplyProtocolConfig({
                    protocol: dex_.dex,
                    supplyToken: dex_.tokenA,
                    expandPercent: 50 * 1e2, // 50%
                    expandDuration: 1 hours, // 1 hour
                    baseWithdrawalLimitInUSD: dex_.baseWithdrawalLimitInUSD
                });

            setSupplyProtocolLimits(protocolConfigTokenA_);

            SupplyProtocolConfig
                memory protocolConfigTokenB_ = SupplyProtocolConfig({
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
            BorrowProtocolConfig
                memory protocolConfigTokenA_ = BorrowProtocolConfig({
                    protocol: dex_.dex,
                    borrowToken: dex_.tokenA,
                    expandPercent: 50 * 1e2, // 50%
                    expandDuration: 1 hours, // 1 hour
                    baseBorrowLimitInUSD: dex_.baseBorrowLimitInUSD,
                    maxBorrowLimitInUSD: dex_.maxBorrowLimitInUSD
                });

            setBorrowProtocolLimits(protocolConfigTokenA_);

            BorrowProtocolConfig
                memory protocolConfigTokenB_ = BorrowProtocolConfig({
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
        if (vault_.vaultType == TYPE.TYPE_1) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: vault_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_1) {
            BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
                protocol: vault_.vault,
                borrowToken: vault_.borrowToken,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseBorrowLimitInUSD: vault_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: vault_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_2) {
            BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
                protocol: vault_.vault,
                borrowToken: vault_.borrowToken,
                expandPercent: 30 * 1e2, // 30%
                expandDuration: 6 hours, // 6 hours
                baseBorrowLimitInUSD: vault_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: vault_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_3) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                expandPercent: 35 * 1e2, // 35%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: vault_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfig_);
        }
    }

    function updateDexBaseLimits(uint256 dexId, uint256 maxSupplyShares, uint256 maxBorrowShares) internal {
        address dexAddress = getDexAddress(dexId);
        if (dexAddress == address(0)) return;

        (address AddressTokenA, address AddressTokenB) = getDexTokens(dexAddress);

        uint256 maxSupplySharesInUSD = getRawAmount(address(0), maxSupplyShares, 0, true);
        uint256 maxBorrowSharesInUSD = getRawAmount(address(0), maxBorrowShares, 0, false);

        uint256 baseWithdrawalInUSD = (maxSupplySharesInUSD * 45) / 100; // 45% of supply cap
        uint256 baseBorrowInUSD = (maxBorrowSharesInUSD * 60) / 100; // 60% of max borrow cap
        uint256 maxBorrowInUSD = maxBorrowSharesInUSD * 11 / 10; // 10% increase

        Dex memory dex_ = Dex({
            dex: dexAddress,
            tokenA: AddressTokenA,
            tokenB: AddressTokenB,
            smartCollateral: maxSupplySharesInUSD > 0,
            smartDebt: maxBorrowSharesInUSD > 0,
            baseWithdrawalLimitInUSD: baseWithdrawalInUSD,
            baseBorrowLimitInUSD: baseBorrowInUSD,
            maxBorrowLimitInUSD: maxBorrowInUSD
        });
        setDexLimits(dex_);
    }
    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 3_320 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 3_950 * 1e2;
    uint256 public constant weETH_USD_PRICE = 3_350 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 3_750 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 3_750 * 1e2;
    uint256 public constant mETH_USD_PRICE = 3_850 * 1e2;
    uint256 public constant ezETH_USD_PRICE = 3_450 * 1e2;

    uint256 public constant BTC_USD_PRICE = 102_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.15 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.02 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 7.2 * 1e2;

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
        } else if (token == ezETH_ADDRESS) {
            usdPrice = ezETH_USD_PRICE;
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
            token == deUSD_ADDRESS ||
            token == USR_ADDRESS ||
            token == USD0_ADDRESS ||
            token == fxUSD_ADDRESS ||
            token == BOLD_ADDRESS
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
