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

contract PayloadIGP69 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 69;

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

        // Action 1: Set launch allowance to rsETH-ETH dex pool
        action1();

        // Action 2: Set launch allowance to rsETH-ETH<>wstETH, rsETH<>wstETH vaults
        action2();

        // Action 3: Set launch allowance to mETH<>USDC, mETH<>USDT, mETH<>GHO vaults
        action3();

        // Action 4: Collect revenue
        action4();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    /// @notice Action 1: Set launch allowance to rsETH-ETH dex pool
    function action1() internal {
        {
            // rsETH-ETH
            Dex memory DEX_rsETH_ETH = Dex({
                dex: getDexAddress(13),
                tokenA: rsETH_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 20_000_000, // $20M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_rsETH_ETH); // Smart Collateral

            DEX_FACTORY.setDexAuth(getDexAddress(13), TEAM_MULTISIG, false);
        }
    }

    // @notice Action 2: Set launch allowance to rsETH-ETH<>wstETH, rsETH<>wstETH vaults
    function action2() internal {
            {
                // [TYPE 2] rsETH-ETH<>wstETH | Smart collateral & debt
            Vault memory VAULT_rsETH_ETH_AND_wstETH = Vault({
                vault: getVaultAddress(78),
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // $0
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 18_000_000 // $18M
            });

            setVaultLimits(VAULT_rsETH_ETH_AND_wstETH); // TYPE_2 => 78

            VAULT_FACTORY.setVaultAuth(
                getVaultAddress(78),
                TEAM_MULTISIG,
                false
            );
        }

        {
            // [TYPE 1] rsETH<>wstETH | collateral & debt
            Vault memory VAULT_rsETH_AND_wstETH = Vault({
                vault: getVaultAddress(79),
                vaultType: TYPE.TYPE_1,
                supplyToken: rsETH_ADDRESS,
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 18_000_000 // $18M
            });

            setVaultLimits(VAULT_rsETH_AND_wstETH); // TYPE_1 => 79

            VAULT_FACTORY.setVaultAuth(
                getVaultAddress(79),
                TEAM_MULTISIG,
                false
            );
        }
    }

    /// @notice Action 3: Set launch allowance to mETH<>USDC, mETH<>USDT, mETH<>GHO vaults
    function action3() internal {
        {
            address mETH_USDC_VAULT = getVaultAddress(81);

            // [TYPE 1] mETH<>USDC | collateral & debt
            Vault memory VAULT_mETH_USDC = Vault({
                vault: mETH_USDC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: mETH_ADDRESS,
                borrowToken: USDC_ADDRESS,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_mETH_USDC); // TYPE_1 => 81

            VAULT_FACTORY.setVaultAuth(mETH_USDC_VAULT, TEAM_MULTISIG, false);
        }

        {
            address mETH_USDT_VAULT = getVaultAddress(82);

            // [TYPE 1] mETH<>USDT | collateral & debt
            Vault memory VAULT_mETH_USDT = Vault({
                vault: mETH_USDT_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: mETH_ADDRESS,
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_mETH_USDT); // TYPE_1 => 82

            VAULT_FACTORY.setVaultAuth(mETH_USDT_VAULT, TEAM_MULTISIG, false);
        }

        {
            address mETH_GHO_VAULT = getVaultAddress(83);

            // [TYPE 1] mETH<>GHO | collateral & debt
            Vault memory VAULT_mETH_GHO = Vault({
                vault: mETH_GHO_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: mETH_ADDRESS,
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_mETH_GHO); // TYPE_1 => 83

            VAULT_FACTORY.setVaultAuth(mETH_GHO_VAULT, TEAM_MULTISIG, false);
        }
    }

    /// @notice Action 4: Collect revenue
    function action4() internal {
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
    uint256 public constant ETH_USD_PRICE = 3_750 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 4_450 * 1e2;
    uint256 public constant weETH_USD_PRICE = 3_950 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 3_850 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 3_750 * 1e2;
    uint256 public constant mETH_USD_PRICE = 3_850 * 1e2;

    uint256 public constant BTC_USD_PRICE = 102_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1 * 1e2;

    uint256 public constant INST_USD_PRICE = 8 * 1e2;

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
