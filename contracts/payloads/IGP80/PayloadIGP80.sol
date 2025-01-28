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

    bool public skip_deusd_usdc_dex_auth_removal;

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

        // Action 6: Update wstETH-ETH DEX Lower Range
        action6();

        // Action 7: Update weETHs-ETH DEX Lower Range and Trading Fee
        action7();

        // Action 8: Withdraw ETH from Reserve to team multisig
        action8();

        // Action 9: Discontinue fGHO rewards
        action9();

        // Action 10: Double limits for sUSDe-USDT/USDT T2 Vault
        action10();

    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Team Multisig Actions      |
     * |__________________________________
     */
    function setState(
        bool skip_deusd_usdc_dex_auth_removal_
    ) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }

        skip_deusd_usdc_dex_auth_removal = skip_deusd_usdc_dex_auth_removal_;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Set dust limits for USDC collateral vaults
    function action1() internal {
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

        address deUSD_USDC_DEX = getDexAddress(19);

        if (!PayloadIGP80(ADDRESS_THIS).skip_deusd_usdc_dex_auth_removal()) {
            DEX_FACTORY.setDexAuth(
                deUSD_USDC_DEX,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 3: Set dust allowance for USR-USDC DEX
    function action3() internal {
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
                baseWithdrawalLimit: 5_000 * 1e18 // 5k shares (10k)
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
                baseDebtCeiling: 5_000 * 1e18, // 5k shares ($10k)
                maxDebtCeiling: 10_000 * 1e18 // 10k shares ($20k)
            });

            IFluidDex(USDC_USDT_DEX_ADDRESS).updateUserBorrowConfigs(config_);
        }

        VAULT_FACTORY.setVaultAuth(
                sUSDe_USDT__USDC_USDT_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
    }
    
    // @notice Action 5:  Set dust allowance for USDe-USDT<>USDC-USDT T4 vault
    function action5() internal {
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
                baseWithdrawalLimit: 5_000 * 1e18 // 5k shares (10k)
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
                baseDebtCeiling: 5_000 * 1e18, // 5k shares ($10k)
                maxDebtCeiling: 10_000 * 1e18 // 10k shares ($20k)
            });

            IFluidDex(USDC_USDT_DEX_ADDRESS).updateUserBorrowConfigs(config_);
        }

        VAULT_FACTORY.setVaultAuth(
                USDe_USDT__USDC_USDT_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
    }

    // @notice Action 6: Update wstETH-ETH DEX Lower Range
    function action6() internal {
        address wstETH_ETH_DEX_ADDRESS = getDexAddress(1);

        {
            // Update Lower Range
            IFluidDex(wstETH_ETH_DEX_ADDRESS).updateRangePercents(
                0.0001 * 1e4,
                0.075 * 1e4,
                0
            );
        }
    }

    // @notice Action 7: Update weETHs-ETH DEX Lower Range and Fee %
    function action7() internal {
        address weETHs_ETH_DEX_ADDRESS = getDexAddress(14);

        {
            // Update Lower Range
            IFluidDex(weETHs_ETH_DEX_ADDRESS).updateRangePercents(
                0.0001 * 1e4,
                0.1 * 1e4,
                5 days
            );
        }
        
        {
            //Update Trading Fee
            IFluidDex(weETHs_ETH_DEX_ADDRESS).updateFeeAndRevenueCut(
                0.05 * 1e4,
                0
            );
        }
    }

    // @notice Action 8: Withdraw ETH from Reserve to team multisig
    function action8() internal {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = ETH_ADDRESS;
        amounts[0] = 500 ether; // 500 ETH

        FLUID_RESERVE.withdrawFunds(tokens, amounts, TEAM_MULTISIG);
    }

    // @notice Action 9: Discontinue fGHO rewards
    function action9() internal {
        address[] memory protocols = new address[](1);
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        address fGHO_REWARDS_ADDRESS = 0x95755A4552690a53d7360B7e16155867868ae964;

        {
            /// fGHO
            IFTokenAdmin(F_GHO_ADDRESS).updateRewards(
                fGHO_REWARDS_ADDRESS
            );

            uint256 allowance = 210_000 * 1e18; // 210K GHO

            protocols[0] = F_GHO_ADDRESS;
            tokens[0] = GHO_ADDRESS;
            amounts[0] = allowance;
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    // @notice Action 10: Double limits for sUSDe-USDT/USDT T2 Vault
    function action10() internal {
        address sUSDe_USDT__USDT_VAULT = getVaultAddress(92);

        {
            // [TYPE 2] sUSDe-USDT<>USDT | smart collateral & debt
            Vault memory VAULT_sUSDe_USDT = Vault({
                vault: sUSDe_USDT__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 30_000_000, // $30M // 2x
                maxBorrowLimitInUSD: 60_000_000 // $60M // 2x
            });

            setVaultLimits(VAULT_sUSDe_USDT); // TYPE_2 => 92
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
