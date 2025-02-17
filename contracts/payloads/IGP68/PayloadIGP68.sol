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

contract PayloadIGP68 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 68;

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

        // Action 1: Set launch allowance to weETHs-ETH dex pool
        action1();

        // Action 2: Set launch allowance to weETHs-ETH<>wstETH vault
        action2();

        // Action 3: Increase ETH-USDC Dex Pool and Vaults Limits
        action3();

        // Action 4: Withdraw funds from Reserve
        action4();

        // Action 5: Set dust allowance to mETH<>USDC, mETH<>USDT, mETH<>GHO vaults
        action5();

        // Action 6: Update USDC, USDT, GHO and USDe market rates.
        action6();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */
    /// @notice Action 1: Set launch allowance to weETHs-ETH dex pool
    function action1() internal {
        {
            // weETHs-ETH
            Dex memory DEX_weETHs_ETH = Dex({
                dex: getDexAddress(14),
                tokenA: weETHs_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_weETHs_ETH); // Smart Collateral

            DEX_FACTORY.setDexAuth(getDexAddress(14), TEAM_MULTISIG, false);
        }
    }

    /// @notice Action 2: Set launch allowance to weETHs-ETH<>wstETH vault
    function action2() internal {
        {
            // [TYPE 2] weETHs-ETH<>wstETH | Smart collateral & debt
            Vault memory VAULT_weETHs_ETH_AND_wstETH = Vault({
                vault: getVaultAddress(80),
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // $0
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 9_500_000 // $9.5M
            });

            setVaultLimits(VAULT_weETHs_ETH_AND_wstETH); // TYPE_2 => 80

            VAULT_FACTORY.setVaultAuth(
                getVaultAddress(80),
                TEAM_MULTISIG,
                false
            );
        }
    }

    /// @notice Action 3: Increase ETH-USDC Dex Pool and Vaults Limits
    function action3() internal {
        address ETH_USDC_DEX_ADDRESS = getDexAddress(12);
        address ETH_USDC_VAULT_ADDRESS = getVaultAddress(77);

        {
            // ETH-USDC Dex Limits
            Dex memory DEX_ETH_USDC = Dex({
                dex: ETH_USDC_DEX_ADDRESS,
                tokenA: ETH_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 15_000_000, // $15M
                baseBorrowLimitInUSD: 12_000_000, // $12M
                maxBorrowLimitInUSD: 30_000_000 // $30M
            });
            setDexLimits(DEX_ETH_USDC); // Smart Collateral and Smart Debt
        }

        {
            // Update Max Supply Shares
            IFluidDex(ETH_USDC_DEX_ADDRESS).updateMaxSupplyShares(15_000_000 * 1e18); // 15M
        }

        {
            // Update Max Borrow Shares
            IFluidDex(ETH_USDC_DEX_ADDRESS).updateMaxBorrowShares(10_000_000 * 1e18); // 10M
        }

        {   // Update ETH-USDC vault borrow shares limit
            IFluidAdminDex.UserBorrowConfig[]
                memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
            config_[0] = IFluidAdminDex.UserBorrowConfig({
                user: ETH_USDC_VAULT_ADDRESS,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours, // 12 hours
                baseDebtCeiling: 5_000_000 * 1e18, // 5M shares
                maxDebtCeiling: 10_000_000 * 1e18 // 10M shares
            });

            IFluidDex(ETH_USDC_DEX_ADDRESS).updateUserBorrowConfigs(
                config_
            );
        }
    }

    /// @notice Action 4: Withdraw funds from Reserve
    function action4() internal {
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        tokens[0] = ETH_ADDRESS;
        amounts[0] = 300 * 1e18; // 300 ETH

        tokens[1] = WBTC_ADDRESS;
        amounts[1] =
            IERC20(WBTC_ADDRESS).balanceOf(address(FLUID_RESERVE)) -
            10;

        FLUID_RESERVE.withdrawFunds(tokens, amounts, TEAM_MULTISIG);
    }

    /// @notice Action 5: Set dust allowance to mETH<>USDC, mETH<>USDT, mETH<>GHO vaults
    function action5() internal {
        {
            address mETH_USDC_VAULT = getVaultAddress(81);

            // [TYPE 1] mETH<>USDC | collateral & debt
            Vault memory VAULT_mETH_USDC = Vault({
                vault: mETH_USDC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: mETH_ADDRESS,
                borrowToken: USDC_ADDRESS,
                baseWithdrawalLimitInUSD: 20_000, // $20k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_mETH_USDC); // TYPE_1 => 81

            VAULT_FACTORY.setVaultAuth(mETH_USDC_VAULT, TEAM_MULTISIG, true);
        }

        {
            address mETH_USDT_VAULT = getVaultAddress(82);

            // [TYPE 1] mETH<>USDT | collateral & debt
            Vault memory VAULT_mETH_USDT = Vault({
                vault: mETH_USDT_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: mETH_ADDRESS,
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 20_000, // $20k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_mETH_USDT); // TYPE_1 => 82

            VAULT_FACTORY.setVaultAuth(mETH_USDT_VAULT, TEAM_MULTISIG, true);
        }

        {
            address mETH_GHO_VAULT = getVaultAddress(83);

            // [TYPE 1] mETH<>GHO | collateral & debt
            Vault memory VAULT_mETH_GHO = Vault({
                vault: mETH_GHO_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: mETH_ADDRESS,
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 20_000, // $20k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_mETH_GHO); // TYPE_1 => 83

            VAULT_FACTORY.setVaultAuth(mETH_GHO_VAULT, TEAM_MULTISIG, true);
        }
    }

    /// @notice Action 6: Update USDC, USDT, GHO and USDe market rates.
    function action6() internal {
        FluidLiquidityAdminStructs.RateDataV2Params[]
            memory params_ = new FluidLiquidityAdminStructs.RateDataV2Params[](
                4
            );

        params_[0] = FluidLiquidityAdminStructs.RateDataV2Params({
            token: USDC_ADDRESS, // USDC
            kink1: 85 * 1e2, // 85%
            kink2: 93 * 1e2, // 93%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 12 * 1e2, // 12%
            rateAtUtilizationKink2: 15 * 1e2, // 15%
            rateAtUtilizationMax: 40 * 1e2 // 40%
        });

        params_[1] = FluidLiquidityAdminStructs.RateDataV2Params({
            token: USDT_ADDRESS, // USDT
            kink1: 85 * 1e2, // 85%
            kink2: 93 * 1e2, // 93%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 12 * 1e2, // 12%
            rateAtUtilizationKink2: 15 * 1e2, // 15%
            rateAtUtilizationMax: 40 * 1e2 // 40%
        });

        params_[2] = FluidLiquidityAdminStructs.RateDataV2Params({
            token: GHO_ADDRESS, // GHO
            kink1: 85 * 1e2, // 85%
            kink2: 93 * 1e2, // 93%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 12 * 1e2, // 12%
            rateAtUtilizationKink2: 15 * 1e2, // 15%
            rateAtUtilizationMax: 40 * 1e2 // 40%
        });

        params_[3] = FluidLiquidityAdminStructs.RateDataV2Params({
            token: USDe_ADDRESS, // USDe
            kink1: 85 * 1e2, // 85%
            kink2: 93 * 1e2, // 93%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 12 * 1e2, // 12%
            rateAtUtilizationKink2: 15 * 1e2, // 15%
            rateAtUtilizationMax: 40 * 1e2 // 40%
        });

        LIQUIDITY.updateRateDataV2s(params_);
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
    uint256 public constant ETH_USD_PRICE = 4_000 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 4_750 * 1e2;
    uint256 public constant weETH_USD_PRICE = 4_250 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 4_150 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 4_050 * 1e2;
    uint256 public constant mETH_USD_PRICE = 4_050 * 1e2;

    uint256 public constant BTC_USD_PRICE = 105_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1 * 1e2;

    uint256 public constant INST_USD_PRICE = 9 * 1e2;

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
        } else if (token == cbBTC_ADDRESS || token == WBTC_ADDRESS) {
            usdPrice = BTC_USD_PRICE;
            decimals = 8;
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
            usdPrice = INST_USD_PRICE;
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
