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

contract PayloadIGP80 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 80;

    bool public skipAction1;
    uint256 public deusd_usdc_dex_id;
    bool public skipAction3;
    bool public skipAction4;
    bool public skipAction5;
    bool public isExecutable;

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
        if (!PayloadIGP80(ADDRESS_THIS).isExecutable()) {
            revert("IGP-80 Execution not executable");
        }

        require(address(this) == address(TIMELOCK), "not-valid-caller");

        // Action 1: Set dust limits for USDC collateral vaults
        action1();

        // Action 2: Remove Multisig as auth from deUSD-USDC DEX
        action2();

        // Action 3: Set dust allowance for USR-USDC DEX
        action3();

        // Action 4: Set dust allowance for sUSDe-USDT<>USDC-USDT T4 vault
        action4();

        // Action 5: Set dust allowance for USDe-USDT<>USDC-USDT T4 vault
        action5();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Team Multisig Actions      |
     * |__________________________________
     */
    function setState(
        bool skipAction1_,
        uint256 deusd_usdc_dex_id,
        bool skipAction3_,
        bool skipAction4_,
        bool skipAction5_,
        bool isExecutable_
    ) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }

        skipAction1 = skipAction1_;
        deUSD_USDC_DEX_ID = deusd_usdc_dex_id;
        skipAction3 = skipAction3_;
        skipAction4 = skipAction4_;
        skipAction5 = skipAction5_;
        isExecutable = isExecutable_;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Set dust limits for USDC collateral vaults
    function action1() internal {
        if (PayloadIGP80(ADDRESS_THIS).skipAction1()) return;

        {
            address USDC_ETH_VAULT = getVaultAddress(100);

            // [TYPE 1] USDC<>ETH | collateral & debt
            Vault memory VAULT_USDC_ETH = Vault({
                vault: USDC_ETH_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: USDC_ADDRESS,
                borrowToken: ETH_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_USDC_ETH); // TYPE_1 => 100

            VAULT_FACTORY.setVaultAuth(
                USDC_ETH_VAULT, 
                TEAM_MULTISIG, 
                true
            );
        }

        {
            address USDC_WBTC_VAULT = getVaultAddress(101);

            // [TYPE 1] USDC<>WBTC | collateral & debt
            Vault memory VAULT_USDC_WBTC = Vault({
                vault: USDC_WBTC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: USDC_ADDRESS,
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_USDC_WBTC); // TYPE_1 => 101

            VAULT_FACTORY.setVaultAuth(
                USDC_WBTC_VAULT, 
                TEAM_MULTISIG, 
                true
            );
        }

        {
            address USDC_cbBTC_VAULT = getVaultAddress(102);

            // [TYPE 1] USDC<>cbBTC | collateral & debt
            Vault memory VAULT_USDC_cbBTC = Vault({
                vault: USDC_cbBTC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: USDC_ADDRESS,
                borrowToken: cbBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_USDC_cbBTC); // TYPE_1 => 102

            VAULT_FACTORY.setVaultAuth(
                USDC_cbBTC_VAULT, 
                TEAM_MULTISIG, 
                true
            );
        }
    }

    // @notice Action 2: Remove Multisig as auth from deUSD-USDC DEX
    function action2() internal {
        uint256 deusd_usdc_dex_id = PayloadIGP80(ADDRESS_THIS).deUSD_USDC_DEX_ID();

        if (deusd_usdc_dex_id != 420)
            DEX_FACTORY.setDexAuth(
                getDexAddress(deusd_usdc_dex_id),
                TEAM_MULTISIG,
                false
            );
    }

    // @notice Action 3: Set dust allowance for USR-USDC DEX
    function action3() internal {
        if (PayloadIGP80(ADDRESS_THIS).skipAction3()) return;

        address USR_USDC_DEX = getDexAddress(20);

        {
            // USR-USDC DEX
            {
                // USR-USDC Dex
                Dex memory DEX_USR_USDC = Dex({
                    dex: USR_USDC_DEX,
                    tokenA: USR_ADDRESS,
                    tokenB: USDC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000_000, // $10M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_USR_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(
                    USR_USDC_DEX, 
                    TEAM_MULTISIG, 
                    true
                );
            }
        }
    }

    // @notice Action 4:  Set dust allowance for sUSDe-USDT<>USDC-USDT T4 vault
    function action4() internal {
        if (PayloadIGP80(ADDRESS_THIS).skipAction4()) return;

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
                baseWithdrawalLimit: 10_000 * 1e18 // 10k shares
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
                baseDebtCeiling: 10_000 * 1e18, // 10k shares
                maxDebtCeiling: 20_000 * 1e18 // 20k shares
            });

            IFluidDex(USDC_USDT_DEX_ADDRESS).updateUserBorrowConfigs(config_);
        }
    }
    
    // @notice Action 5:  Set dust allowance for USDe-USDT<>USDC-USDT T4 vault
    function action5() internal {
        if (PayloadIGP80(ADDRESS_THIS).skipAction5()) return;

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
                baseWithdrawalLimit: 10_000 * 1e18 // 10k shares
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
                baseDebtCeiling: 10_000 * 1e18, // 10k shares
                maxDebtCeiling: 20_000 * 1e18 // 20k shares
            });

            IFluidDex(USDC_USDT_DEX_ADDRESS).updateUserBorrowConfigs(config_);
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
