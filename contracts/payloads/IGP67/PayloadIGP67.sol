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

interface IStETHRedemptionProtocol {
    /// @notice Sets `maxLTV` to `maxLTV_` (in 1e2: 1% = 100, 100% = 10000). Must be > 0 and < 100%.
    function setMaxLTV(uint16 maxLTV_) external;
}

contract PayloadIGP67 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 67;

    // State
    uint256 public INST_ETH_VAULT_ID = 0;
    uint256 public INST_ETH_DEX_ID = 0;
    uint256 public ETH_USDC_DEX_ID = 0;
    uint256 public ETH_USDC_VAULT_ID = 0;

    uint256 public CBBTC_WBTC_NEW_CENTER_PRICE = 0;

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

        // Action 1: Set Dust Allowance to rsETH-ETH and weETHs-ETH dex pools
        action1();

        // Action 2: Set Dust Allowance to rsETH-ETH<>wstETH, rsETH<>wstETH, weETHs-ETH<>wstETH vaults
        action2();

        // Action 3: Increase Allowance and LTV of stETH redemption protocol
        action3();

        // Action 4: Remove Team Multisig as Auth from ETH-USDC and INST-ETH dex and vaults
        action4();

        // Action 5: Update Fluid Reserve Contract Implementation
        action5();

        // Action 6: Increase USDC allowance to cbBTC<>USDC and wBTC<>USDC vaults
        action6();

        // Action 7: Update cbBTC-wBTC Dex Config
        action7();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Team Multisig Actions      |
     * |__________________________________
     */
    function setState(
        uint256 inst_eth_dex_id,
        uint256 inst_eth_vault_id,
        uint256 eth_usdc_dex_id,
        uint256 eth_usdc_vault_id,
        uint256 cbBTC_wBTC_new_center_price
    ) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }

        INST_ETH_DEX_ID = inst_eth_dex_id;
        INST_ETH_VAULT_ID = inst_eth_vault_id;
        ETH_USDC_DEX_ID = eth_usdc_dex_id;
        ETH_USDC_VAULT_ID = eth_usdc_vault_id;
        CBBTC_WBTC_NEW_CENTER_PRICE = cbBTC_wBTC_new_center_price;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */
    /// @notice Action 1: Set Dust Allowance to rsETH-ETH & weETHs-ETH dex pools
    function action1() internal {
        {
            // rsETH-ETH
            Dex memory DEX_rsETH_ETH = Dex({
                dex: getDexAddress(13),
                tokenA: rsETH_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 50_000, // $50k
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_rsETH_ETH); // Smart Collateral

            DEX_FACTORY.setDexAuth(getDexAddress(13), TEAM_MULTISIG, true);
        }

        {
            // weETHs-ETH
            Dex memory DEX_weETHs_ETH = Dex({
                dex: getDexAddress(14),
                tokenA: weETHs_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 50_000, // $50k
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_weETHs_ETH); // Smart Collateral

            DEX_FACTORY.setDexAuth(getDexAddress(14), TEAM_MULTISIG, true);
        }
    }

    /// @notice Action 2: Set dust allowance to rsETH-ETH<>wstETH, rsETH<>wstETH, weETHs-ETH<>wstETH vaults
    function action2() internal {
        {
            // [TYPE 2] rsETH-ETH<>wstETH | Smart collateral & debt
            Vault memory VAULT_rsETH_ETH_AND_wstETH = Vault({
                vault: getVaultAddress(78),
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // $0
                baseBorrowLimitInUSD: 40_000, // $40k
                maxBorrowLimitInUSD: 50_000 // $50k
            });

            setVaultLimits(VAULT_rsETH_ETH_AND_wstETH); // TYPE_2 => 78

            VAULT_FACTORY.setVaultAuth(
                getVaultAddress(78),
                TEAM_MULTISIG,
                true
            );
        }

        {
            // [TYPE 1] rsETH<>wstETH | collateral & debt
            Vault memory VAULT_rsETH_AND_wstETH = Vault({
                vault: getVaultAddress(79),
                vaultType: TYPE.TYPE_1,
                supplyToken: rsETH_ADDRESS,
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 50_000, // $50k
                baseBorrowLimitInUSD: 40_000, // $40k
                maxBorrowLimitInUSD: 50_000 // $50k
            });

            setVaultLimits(VAULT_rsETH_AND_wstETH); // TYPE_1 => 79

            VAULT_FACTORY.setVaultAuth(
                getVaultAddress(79),
                TEAM_MULTISIG,
                true
            );
        }

        {
            // [TYPE 2] weETHs-ETH<>wstETH | Smart collateral & debt
            Vault memory VAULT_weETHs_ETH_AND_wstETH = Vault({
                vault: getVaultAddress(80),
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // $0
                baseBorrowLimitInUSD: 40_000, // $40k
                maxBorrowLimitInUSD: 50_000 // $50k
            });

            setVaultLimits(VAULT_weETHs_ETH_AND_wstETH); // TYPE_2 => 80

            VAULT_FACTORY.setVaultAuth(
                getVaultAddress(80),
                TEAM_MULTISIG,
                true
            );
        }
    }

    /// @notice Action 3: Increase Allowance and LTV of stETH redemption protocol
    function action3() internal {
        {
            // Increase Allowance to 10k ETH
            uint256 amount_ = getRawAmount(ETH_ADDRESS, 10_000, 0, false);

            BorrowProtocolConfig memory config_ = BorrowProtocolConfig({
                protocol: 0x1F6B2bFDd5D1e6AdE7B17027ff5300419a56Ad6b,
                borrowToken: ETH_ADDRESS,
                expandPercent: 0,
                expandDuration: 1,
                baseBorrowLimitInUSD: amount_,
                maxBorrowLimitInUSD: (amount_ * 1001) / 1000
            });

            setBorrowProtocolLimits(config_);
        }

        {
            // Increase LTV to 95%
            IStETHRedemptionProtocol(0x1F6B2bFDd5D1e6AdE7B17027ff5300419a56Ad6b)
                .setMaxLTV(95 * 1e2);
        }
    }

    /// @notice Action 4: Remove Team Multisig as Auth from ETH-USDC and INST-ETH dex and vaults
    function action4() internal {
        uint256 eth_usdc_dex_id = PayloadIGP67(ADDRESS_THIS).ETH_USDC_DEX_ID();
        uint256 eth_usdc_vault_id = PayloadIGP67(ADDRESS_THIS)
            .ETH_USDC_VAULT_ID();
        uint256 inst_eth_dex_id = PayloadIGP67(ADDRESS_THIS).INST_ETH_DEX_ID();
        uint256 inst_eth_vault_id = PayloadIGP67(ADDRESS_THIS)
            .INST_ETH_VAULT_ID();

        if (inst_eth_dex_id != 420)
            DEX_FACTORY.setDexAuth(
                getDexAddress(inst_eth_dex_id),
                TEAM_MULTISIG,
                false
            );
        if (eth_usdc_dex_id != 420)
            DEX_FACTORY.setDexAuth(
                getDexAddress(eth_usdc_dex_id),
                TEAM_MULTISIG,
                false
            );

        if (inst_eth_vault_id != 420)
            VAULT_FACTORY.setVaultAuth(
                getVaultAddress(inst_eth_vault_id),
                TEAM_MULTISIG,
                false
            );
        if (eth_usdc_vault_id != 420)
            VAULT_FACTORY.setVaultAuth(
                getVaultAddress(eth_usdc_vault_id),
                TEAM_MULTISIG,
                false
            );
    }

    /// @notice Action 5: Update Fluid Reserve Contract Implementation
    function action5() internal {
        IProxy(address(FLUID_RESERVE)).upgradeToAndCall(
            address(0xE2283Cdec12c6AF6C51557BB4640c640800d7060),
            abi.encode()
        );
    }

    /// @notice Action 6: Increase USDC allowance to cbBTC<>USDC and wBTC<>USDC vaults
    function action6() internal {
        address[] memory protocols = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        {
            // wBTC<>USDCs
            address wBTC_USDC_VAULT = getVaultAddress(21);

            uint256 allowance = IERC20(USDC_ADDRESS).allowance(
                address(FLUID_RESERVE),
                wBTC_USDC_VAULT
            );

            protocols[0] = wBTC_USDC_VAULT;
            tokens[0] = USDC_ADDRESS;
            amounts[0] = allowance + (6_000 * 1e6);
        }

        {
            // cbBTC<>USDC
            address cbBTC_USDC_VAULT = getVaultAddress(29);

            uint256 allowance = IERC20(USDC_ADDRESS).allowance(
                address(FLUID_RESERVE),
                cbBTC_USDC_VAULT
            );

            protocols[1] = cbBTC_USDC_VAULT;
            tokens[1] = USDC_ADDRESS;
            amounts[1] = allowance + (4_000 * 1e6);
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    /// @notice Action 7: Update cbBTC-wBTC Dex Config
    function action7() internal {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        uint256 newCenterPrice_ = PayloadIGP67(ADDRESS_THIS)
            .CBBTC_WBTC_NEW_CENTER_PRICE();

        if (newCenterPrice_ == 420) return;

        require(
            newCenterPrice_ > 997 && newCenterPrice_ <= 998,
            "new-center-price-is-too-high"
        );

        // Update Center Price Limits between 0.3% to 0.2%
        uint256 minCenterPrice_ = (newCenterPrice_ * 1e27) / 1000;
        uint256 maxCenterPrice_ = uint256(1e27 * 1000) / newCenterPrice_;

        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateCenterPriceLimits(
            maxCenterPrice_,
            minCenterPrice_
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
    uint256 public constant ETH_USD_PRICE = 3_900 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 4_650 * 1e2;
    uint256 public constant weETH_USD_PRICE = 4_150 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 4_050 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 3_950 * 1e2;

    uint256 public constant BTC_USD_PRICE = 101_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1 * 1e2;

    uint256 public constant INST_USD_PRICE = 8.5 * 1e2;

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
