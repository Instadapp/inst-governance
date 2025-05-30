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

contract PayloadIGP81 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 81;

    bool public skipAction4;
    bool public skipAction7;
    bool public skipAction8;
    bool public skipAction9;

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

        // Action 1: Set dust limits for ezETH-ETH DEX and ezETH<>wstETH T1 & ezETH-ETH<>wstETH T2 vaults
        action1();

        // Action 2: Increase sUSDe-USDT<>USDT supply and borrow cap
        action2();

        // Action 3: Set dust allowance for cbBTC-USDT DEX T4 vault
        action3();

        // Action 4: Reduce max supply shares and max borrow limit for USDe-USDT<>USDT
        action4();

        // Action 5: Increase LTV, LT and LML for USDe-USDT<>USDT
        action5();

        // Action 6: Update the upper and lower range of LBTC<>cbBTC DEX
        action6();

        // Action 7: Remove Multisig as auth from USR-USDC DEX
        action7();

        // Action 8: Update allowance for sUSDe-USDT<>USDC-USDT T4 vault
        action8();

        // Action 9: Update allowance for USDe-USDT<>USDC-USDT T4 vault
        action9();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Team Multisig Actions      |
     * |__________________________________
     */
    function setState(
        bool skipAction4_,
        bool skipAction7_,
        bool skipAction8_,
        bool skipAction9_
    ) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }
        skipAction4 = skipAction4_;
        skipAction7 = skipAction7_;
        skipAction8 = skipAction8_;
        skipAction9 = skipAction9_;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Set dust limits for ezETH-ETH DEX and ezETH<>wstETH T1 & ezETH-ETH<>wstETH T2 vaults
    function action1() internal {
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
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_ezETH_ETH); // Smart Collateral

                DEX_FACTORY.setDexAuth(ezETH_ETH_DEX, TEAM_MULTISIG, true);
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
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_ezETH_wstETH); // TYPE_1 => 103

            VAULT_FACTORY.setVaultAuth(
                ezETH__wstETH_VAULT,
                TEAM_MULTISIG,
                true
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
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_ezETH_ETH_wstETH); // TYPE_2 => 104

            VAULT_FACTORY.setVaultAuth(
                ezETH_ETH__wstETH_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 2: Increase sUSDe-USDT<>USDT supply and borrow cap
    function action2() internal {
        address sUSDe_USDT_DEX_ADDRESS = getDexAddress(15);
        address sUSDe_USDT__USDT_VAULT = getVaultAddress(92);

        {
            // Increase Max Supply Shares
            IFluidDex(sUSDe_USDT_DEX_ADDRESS).updateMaxSupplyShares(
                25_000_000 * 1e18 // 25M shares // $50M
            );
        }

        {
            // Update sUSDe-USDT<>USDT vault supply shares limit
            IFluidAdminDex.UserSupplyConfig[]
                memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: sUSDe_USDT__USDT_VAULT,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimit: 25_000_000 * 1e18 // 25M shares // $50M
            });

            IFluidDex(sUSDe_USDT_DEX_ADDRESS).updateUserSupplyConfigs(config_);
        }

        {
            // [TYPE 2] sUSDe-USDT<>USDT | smart collateral & debt
            Vault memory VAULT_sUSDe_USDT_USDT = Vault({
                vault: sUSDe_USDT__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 22_500_000, // $22.5M
                maxBorrowLimitInUSD: 45_000_000 // $45M
            });

            setVaultLimits(VAULT_sUSDe_USDT_USDT); // TYPE_2 => 92
        }
    }

    // @notice Action 3: Set dust allowance for cbBTC-USDT DEX T4 vault
    function action3() internal {
        address cbBTC_USDT_DEX_ADDRESS = getDexAddress(22);

        {
            // dust limits
            Dex memory DEX_cbBTC_USDT = Dex({
                dex: cbBTC_USDT_DEX_ADDRESS,
                tokenA: cbBTC_ADDRESS,
                tokenB: USDT_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });
            setDexLimits(DEX_cbBTC_USDT); // Smart Collateral & Smart Debt

            DEX_FACTORY.setDexAuth(cbBTC_USDT_DEX_ADDRESS, TEAM_MULTISIG, true);
        }

        {
            address cbBTC_USDT__cbBTC_USDT_VAULT_ADRESS = getVaultAddress(105);

            // Set team multisig as vault auth for cbBTC_USDT T4 Vault
            VAULT_FACTORY.setVaultAuth(
                cbBTC_USDT__cbBTC_USDT_VAULT_ADRESS,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 4: Reduce max supply shares and max borrow limit for USDe-USDT<>USDT
    function action4() internal {
        if (PayloadIGP81(ADDRESS_THIS).skipAction4()) return;

        address USDe_USDT_DEX_ADDRESS = getDexAddress(18);
        address USDe_USDT__USDT_VAULT = getVaultAddress(93);

        {
            // Dexcrease Max Supply Shares
            IFluidDex(USDe_USDT_DEX_ADDRESS).updateMaxSupplyShares(
                10_000_000 * 1e18 // 10M shares // $20M
            );
        }

        {
            // Update USDe-USDT<>USDT vault supply shares limit
            IFluidAdminDex.UserSupplyConfig[]
                memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: USDe_USDT__USDT_VAULT,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimit: 5_000_000 * 1e18 // 5M shares // $10M
            });

            IFluidDex(USDe_USDT_DEX_ADDRESS).updateUserSupplyConfigs(config_);
        }

        {
            // [TYPE 2] USDe-USDT<>USDT | smart collateral & debt
            Vault memory VAULT_USDe_USDT_USDT = Vault({
                vault: USDe_USDT__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 9_000_000, // $9M
                maxBorrowLimitInUSD: 18_000_000 // $18M
            });

            setVaultLimits(VAULT_USDe_USDT_USDT); // TYPE_2 => 93
        }
    }

    // @notice Action 5: Increase LTV, LT and LML for USDe-USDT<>USDT
    function action5() internal {
        address USDe_USDT__USDT_VAULT = getVaultAddress(93);

        uint256 CF = 94 * 1e2;
        uint256 LT = 95 * 1e2;
        uint256 LML = 96 * 1e2;

        IFluidVaultT1(USDe_USDT__USDT_VAULT).updateLiquidationMaxLimit(LML);
        IFluidVaultT1(USDe_USDT__USDT_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(USDe_USDT__USDT_VAULT).updateCollateralFactor(CF);
    }

    // Action 6: Update the upper and lower range of LBTC<>cbBTC DEX
    function action6() internal {
        address LBTC_cbBTC_DEX = getDexAddress(17);

        // updates the upper and lower range
        IFluidDex(LBTC_cbBTC_DEX).updateRangePercents(
            0.1 * 1e4, // +0.1%
            0.3 * 1e4, // -0.3%
            2 days
        );
    }

    // @notice Action 7: Remove Multisig as auth from USR-USDC DEX
    function action7() internal {
        if (PayloadIGP81(ADDRESS_THIS).skipAction7()) return;

        address USR_USDC_DEX = getDexAddress(20);

        DEX_FACTORY.setDexAuth(USR_USDC_DEX, TEAM_MULTISIG, false);
    }

    // @notice Action 8: Update allowance for sUSDe-USDT<>USDC-USDT T4 vault
    function action8() internal {
        if (PayloadIGP81(ADDRESS_THIS).skipAction8()) return;

        address sUSDe_USDT_DEX_ADDRESS = getDexAddress(15);
        address USDC_USDT_DEX_ADDRESS = getDexAddress(2);
        address sUSDe_USDT__USDC_USDT_VAULT_ADDRESS = getVaultAddress(98);

        {
            // Update sUSDe-USDT<>USDC-USDT vault supply shares limit
            IFluidAdminDex.UserSupplyConfig[]
                memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: sUSDe_USDT__USDC_USDT_VAULT_ADDRESS,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimit: 5_000_000 * 1e18 // 5M shares
            });

            IFluidDex(sUSDe_USDT_DEX_ADDRESS).updateUserSupplyConfigs(config_);
        }

        {
            // Update sUSDe-USDT<>USDC-USDT vault borrow shares limit
            IFluidAdminDex.UserBorrowConfig[]
                memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
            config_[0] = IFluidAdminDex.UserBorrowConfig({
                user: sUSDe_USDT__USDC_USDT_VAULT_ADDRESS,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours, // 12 hours
                baseDebtCeiling: 5_000_000 * 1e18, // 5M shares
                maxDebtCeiling: 15_000_000 * 1e18 // 15M shares
            });

            IFluidDex(USDC_USDT_DEX_ADDRESS).updateUserBorrowConfigs(config_);
        }

        VAULT_FACTORY.setVaultAuth(
            sUSDe_USDT__USDC_USDT_VAULT_ADDRESS,
            TEAM_MULTISIG,
            false
        );
    }

    // @notice Action 9:  Update allowance for USDe-USDT<>USDC-USDT T4 vault
    function action9() internal {
        if (PayloadIGP81(ADDRESS_THIS).skipAction9()) return;

        address USDe_USDT_DEX_ADDRESS = getDexAddress(18);
        address USDC_USDT_DEX_ADDRESS = getDexAddress(2);
        address USDe_USDT__USDC_USDT_VAULT_ADDRESS = getVaultAddress(99);

        {
            // Update USDe-USDT<>USDC-USDT vault supply shares limit
            IFluidAdminDex.UserSupplyConfig[]
                memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: USDe_USDT__USDC_USDT_VAULT_ADDRESS,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimit: 5_000_000 * 1e18 // 5M shares
            });

            IFluidDex(USDe_USDT_DEX_ADDRESS).updateUserSupplyConfigs(config_);
        }

        {
            // Update USDe-USDT<>USDC-USDT vault borrow shares limit
            IFluidAdminDex.UserBorrowConfig[]
                memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
            config_[0] = IFluidAdminDex.UserBorrowConfig({
                user: USDe_USDT__USDC_USDT_VAULT_ADDRESS,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours, // 12 hours
                baseDebtCeiling: 5_000_000 * 1e18, // 5M shares
                maxDebtCeiling: 10_000_000 * 1e18 // 10M shares
            });

            IFluidDex(USDC_USDT_DEX_ADDRESS).updateUserBorrowConfigs(config_);
        }

        VAULT_FACTORY.setVaultAuth(
            USDe_USDT__USDC_USDT_VAULT_ADDRESS,
            TEAM_MULTISIG,
            false
        );
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
            token == USR_ADDRESS
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
