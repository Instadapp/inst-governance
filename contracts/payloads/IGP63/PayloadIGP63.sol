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
import { IERC20 } from "../common/interfaces/IERC20.sol";

import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";

contract PayloadIGP63 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 63;

    function propose(string memory description) external {
        require(
            msg.sender == PROPOSER ||
                msg.sender == TEAM_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG_2 ||
                address(this) == PROPOSER_AVO_MULTISIG_3 || 
                address(this) == PROPOSER_AVO_MULTISIG_4,
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

        // Action 1: Increase weETH-ETH_wstETH limits
        action1();

        // Action 2: Update fUSDC and fUSDT Rewards
        action2();

        // Action 3: Lend GHO to fGHO from Treasury
        action3();  

        // Action 4: Update USDC-USDT Dex Config
        action4();

        // Action 5: Update cbBTC-wBTC Dex Config
        action5();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    /// @notice Action 1: Increase weETH-ETH_wstETH limits
    function action1() internal {
        address WEETH_ETH_WSTETH_DEX_ADDRESS = getDexAddress(9);
        address WEETH_ETH_WSTETH_VAULT_ADDRESS = getVaultAddress(74);

        { // Increase Max Supply Shares
            IFluidDex(WEETH_ETH_WSTETH_DEX_ADDRESS).updateMaxSupplyShares(
                6_000 * 1e18 // 6k shares
            );
        }

        { // Increase WEETH-ETH-WSTETH vault limit
            IFluidAdminDex.UserSupplyConfig[] memory config_ = new IFluidDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: WEETH_ETH_WSTETH_VAULT_ADDRESS,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimit: 2_935 * 1e18 // 2935 shares
            });

            IFluidDex(WEETH_ETH_WSTETH_DEX_ADDRESS).updateUserSupplyConfigs(
                config_
            );
        }

        {
            BorrowProtocolConfig memory config_ = BorrowProtocolConfig({
                protocol: WEETH_ETH_WSTETH_VAULT_ADDRESS,
                borrowToken: wstETH_ADDRESS,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours, // 12 hours
                baseBorrowLimitInUSD: 42_000_000, // $42M
                maxBorrowLimitInUSD: 92_000_000 // $92M
            });

            setBorrowProtocolLimits(config_);
        }
    }

    /// @notice Action 2: Update fUSDC and fUSDT Rewards
    function action2() internal {
        address[] memory protocols = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        address fSTABLES_REWARDS_ADDRESS = 0xb75Ec31fd7ad0D823A801be8740B9Fad299ce6d6;

        {
            /// fUSDC
            IFTokenAdmin(F_USDC_ADDRESS).updateRewards(
                fSTABLES_REWARDS_ADDRESS
            );

            uint256 allowance = IERC20(USDC_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_USDC_ADDRESS
            );

            protocols[0] = F_USDC_ADDRESS;
            tokens[0] = USDC_ADDRESS;
            amounts[0] = allowance + (500_000 * 1e6);
        }

        {
            /// fUSDT
            IFTokenAdmin(F_USDT_ADDRESS).updateRewards(
                fSTABLES_REWARDS_ADDRESS
            );

            uint256 allowance = IERC20(USDT_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_USDT_ADDRESS
            );

            protocols[1] = F_USDT_ADDRESS;
            tokens[1] = USDT_ADDRESS;
            amounts[1] = allowance + (500_000 * 1e6);
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    /// @notice Action 3: Lend GHO to fGHO from Treasury
    function action3() internal {
        string[] memory targets = new string[](1);
        bytes[] memory encodedSpells = new bytes[](1);

        string memory depositSignature = "deposit(address,uint256,uint256,uint256)";

        // Spell 1: Deposit GHO into fGHO
        {   
            uint256 GHO_AMOUNT = 4_000_000 * 1e18; // 4M GHO
            targets[0] = "BASIC-D";
            encodedSpells[0] = abi.encodeWithSignature(depositSignature, F_GHO_ADDRESS, GHO_AMOUNT, 0, 0);
        }

        IDSAV2(TREASURY).cast(targets, encodedSpells, address(this));
    }

    /// @notice Action 4: Update USDC-USDT Dex Config
    function action4() internal {
        address USDC_USDT_DEX_ADDRESS = getDexAddress(1);

        { // Update Threshold to 50%
            uint256 threshold_ = 50 * 1e4; // 50%
            IFluidDex(USDC_USDT_DEX_ADDRESS).updateThresholdPercent(
                threshold_,
                threshold_,
                3 hours,
                3 hours
            );
        }
    }

    /// @notice Action 5: Update cbBTC-wBTC Dex Config
    function action5() internal {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        { // Increase Range to +-0.1%
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateRangePercents(0.1 * 1e4, 0.1 * 1e4, 12 hours);
        }

        { // Update Center Price Limits to +-0.2%
            uint256 minCenterPrice_ = (998 * 1e27) / 1000;
            uint256 maxCenterPrice_ = uint256(1e27 * 1000) / 998;
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateCenterPriceLimits(
                maxCenterPrice_,
                minCenterPrice_
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
        if (vault_.vaultType == TYPE.TYPE_3) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimitInUSD: vault_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_2) {
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
    uint256 public constant ETH_USD_PRICE = 3_950 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 4_550 * 1e2;
    uint256 public constant weETH_USD_PRICE = 4_050 * 1e2;

    uint256 public constant BTC_USD_PRICE = 99_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1 * 1e2;

    uint256 public constant INST_USD_PRICE = 7.5 * 1e2;

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
