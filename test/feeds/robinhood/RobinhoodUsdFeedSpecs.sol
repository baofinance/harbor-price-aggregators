// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AAPL_USD} from "@harbor-price/feeds/chainlink/robinhood/AAPL_USD.sol";
import {AMD_USD} from "@harbor-price/feeds/chainlink/robinhood/AMD_USD.sol";
import {AMZN_USD} from "@harbor-price/feeds/chainlink/robinhood/AMZN_USD.sol";
import {ASML_USD} from "@harbor-price/feeds/chainlink/robinhood/ASML_USD.sol";
import {BABA_USD} from "@harbor-price/feeds/chainlink/robinhood/BABA_USD.sol";
import {CLSK_USD} from "@harbor-price/feeds/chainlink/robinhood/CLSK_USD.sol";
import {COIN_USD} from "@harbor-price/feeds/chainlink/robinhood/COIN_USD.sol";
import {CRCL_USD} from "@harbor-price/feeds/chainlink/robinhood/CRCL_USD.sol";
import {CRWV_USD} from "@harbor-price/feeds/chainlink/robinhood/CRWV_USD.sol";
import {DELL_USD} from "@harbor-price/feeds/chainlink/robinhood/DELL_USD.sol";
import {EWY_USD} from "@harbor-price/feeds/chainlink/robinhood/EWY_USD.sol";
import {GME_USD} from "@harbor-price/feeds/chainlink/robinhood/GME_USD.sol";
import {GOOGL_USD} from "@harbor-price/feeds/chainlink/robinhood/GOOGL_USD.sol";
import {INTC_USD} from "@harbor-price/feeds/chainlink/robinhood/INTC_USD.sol";
import {IONQ_USD} from "@harbor-price/feeds/chainlink/robinhood/IONQ_USD.sol";
import {META_USD} from "@harbor-price/feeds/chainlink/robinhood/META_USD.sol";
import {MSFT_USD} from "@harbor-price/feeds/chainlink/robinhood/MSFT_USD.sol";
import {MSTR_USD} from "@harbor-price/feeds/chainlink/robinhood/MSTR_USD.sol";
import {MU_USD} from "@harbor-price/feeds/chainlink/robinhood/MU_USD.sol";
import {NBIS_USD} from "@harbor-price/feeds/chainlink/robinhood/NBIS_USD.sol";
import {NVDA_USD} from "@harbor-price/feeds/chainlink/robinhood/NVDA_USD.sol";
import {ORCL_USD} from "@harbor-price/feeds/chainlink/robinhood/ORCL_USD.sol";
import {PLTR_USD} from "@harbor-price/feeds/chainlink/robinhood/PLTR_USD.sol";
import {QQQ_USD} from "@harbor-price/feeds/chainlink/robinhood/QQQ_USD.sol";
import {RGTI_USD} from "@harbor-price/feeds/chainlink/robinhood/RGTI_USD.sol";
import {RKLB_USD} from "@harbor-price/feeds/chainlink/robinhood/RKLB_USD.sol";
import {SLV_USD} from "@harbor-price/feeds/chainlink/robinhood/SLV_USD.sol";
import {SNDK_USD} from "@harbor-price/feeds/chainlink/robinhood/SNDK_USD.sol";
import {SPCX_USD} from "@harbor-price/feeds/chainlink/robinhood/SPCX_USD.sol";
import {SPY_USD} from "@harbor-price/feeds/chainlink/robinhood/SPY_USD.sol";
import {TSLA_USD} from "@harbor-price/feeds/chainlink/robinhood/TSLA_USD.sol";
import {TSM_USD} from "@harbor-price/feeds/chainlink/robinhood/TSM_USD.sol";
import {USDG_USD} from "@harbor-price/feeds/chainlink/robinhood/USDG_USD.sol";
import {USO_USD} from "@harbor-price/feeds/chainlink/robinhood/USO_USD.sol";

library RobinhoodUsdFeedSpecs {
    struct FeedSpec {
        string ticker;
        address feed;
        uint256 heartbeat;
        address expected;
    }

    function specs() internal pure returns (FeedSpec[] memory s) {
        s = new FeedSpec[](34);
        s[0] = FeedSpec("AAPL", AAPL_USD.FEED, AAPL_USD.HEARTBEAT, 0x6B22A786bAa607d76728168703a39Ea9C99f2cD0);
        s[1] = FeedSpec("AMD", AMD_USD.FEED, AMD_USD.HEARTBEAT, 0x943A29E7ae51A4798823ca9eEd2ed533B2A22C72);
        s[2] = FeedSpec("AMZN", AMZN_USD.FEED, AMZN_USD.HEARTBEAT, 0xD5a1508ceD74c084eBf3cBe853e2C968fB2a651C);
        s[3] = FeedSpec("ASML", ASML_USD.FEED, ASML_USD.HEARTBEAT, 0xB4106147E8cce40b7d46124090d373A71b70f87D);
        s[4] = FeedSpec("BABA", BABA_USD.FEED, BABA_USD.HEARTBEAT, 0x62Cc8F9b5f56a33c9C8A60c8B92779f523c4E984);
        s[5] = FeedSpec("CLSK", CLSK_USD.FEED, CLSK_USD.HEARTBEAT, 0x810c12D3a554Bc47fd39597Fe3b3AAC4941F50eF);
        s[6] = FeedSpec("COIN", COIN_USD.FEED, COIN_USD.HEARTBEAT, 0xA3a468A452940B7D6b69991207B508c609a98Ef2);
        s[7] = FeedSpec("CRCL", CRCL_USD.FEED, CRCL_USD.HEARTBEAT, 0x6652eDf64bA3731C4F2D3ce821A0Fb1f1f6b482a);
        s[8] = FeedSpec("CRWV", CRWV_USD.FEED, CRWV_USD.HEARTBEAT, 0xe1b3aABCAFAd1c94708dc1367dcfF8Aa4407487C);
        s[9] = FeedSpec("DELL", DELL_USD.FEED, DELL_USD.HEARTBEAT, 0x1C6c8cADBe02E19129c39dDB92281cE4c0bf206b);
        s[10] = FeedSpec("EWY", EWY_USD.FEED, EWY_USD.HEARTBEAT, 0xEFdf54610B62A7753Ec30bDc380847c12D32e1D1);
        s[11] = FeedSpec("GME", GME_USD.FEED, GME_USD.HEARTBEAT, 0x27C71df6A64fB476468EdF256CF72c038baB5B67);
        s[12] = FeedSpec("GOOGL", GOOGL_USD.FEED, GOOGL_USD.HEARTBEAT, 0xF6f373a037c30F0e5010d854385cA89185AE638b);
        s[13] = FeedSpec("INTC", INTC_USD.FEED, INTC_USD.HEARTBEAT, 0x3f390C5C24628Ac7C489515402235FeAD71D1913);
        s[14] = FeedSpec("IONQ", IONQ_USD.FEED, IONQ_USD.HEARTBEAT, 0x22EfeC4919baf55F360E0EDee4AbEB26DE4971eb);
        s[15] = FeedSpec("META", META_USD.FEED, META_USD.HEARTBEAT, 0x7C38C00C30BEe9378381E7B6135d7283356D71b1);
        s[16] = FeedSpec("MSFT", MSFT_USD.FEED, MSFT_USD.HEARTBEAT, 0x45C3C877C15E6BA2EBB19eA114Ea508d14C1Af2E);
        s[17] = FeedSpec("MSTR", MSTR_USD.FEED, MSTR_USD.HEARTBEAT, 0x396118bdFB181e6240E74D243F266B061c0edc3D);
        s[18] = FeedSpec("MU", MU_USD.FEED, MU_USD.HEARTBEAT, 0x425EEFdCf05ed6526C3cE61Af99429A228a6d596);
        s[19] = FeedSpec("NBIS", NBIS_USD.FEED, NBIS_USD.HEARTBEAT, 0xE1D87B116Ba0fe898998f1D140339D1fA1E09705);
        s[20] = FeedSpec("NVDA", NVDA_USD.FEED, NVDA_USD.HEARTBEAT, 0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15);
        s[21] = FeedSpec("ORCL", ORCL_USD.FEED, ORCL_USD.HEARTBEAT, 0x0e6a64a2B58A6693a531E6c555f3A5d042eEA844);
        s[22] = FeedSpec("PLTR", PLTR_USD.FEED, PLTR_USD.HEARTBEAT, 0x820ABedFF239034956B7A9d2F0a331f9F075eB4c);
        s[23] = FeedSpec("QQQ", QQQ_USD.FEED, QQQ_USD.HEARTBEAT, 0x80901d846d5D7B030F26B480776EE3b29374C2ae);
        s[24] = FeedSpec("RGTI", RGTI_USD.FEED, RGTI_USD.HEARTBEAT, 0x2A045cF1C49c61c166C036d2f06FA2D2d984f765);
        s[25] = FeedSpec("RKLB", RKLB_USD.FEED, RKLB_USD.HEARTBEAT, 0x045477BF65Aef6f4F2386ad0164579e48381CC74);
        s[26] = FeedSpec("SLV", SLV_USD.FEED, SLV_USD.HEARTBEAT, 0x209b73908e92Ae021826eD79609845451Ecba2ce);
        s[27] = FeedSpec("SNDK", SNDK_USD.FEED, SNDK_USD.HEARTBEAT, 0xfb133Fa4B7b385802B693a293606682Df47109A3);
        s[28] = FeedSpec("SPCX", SPCX_USD.FEED, SPCX_USD.HEARTBEAT, 0xB265810950ba6c5C0Ff821c9963014a56fD8Bffb);
        s[29] = FeedSpec("SPY", SPY_USD.FEED, SPY_USD.HEARTBEAT, 0x319724394D3A0e3669269846abE664Cd621f9f6A);
        s[30] = FeedSpec("TSLA", TSLA_USD.FEED, TSLA_USD.HEARTBEAT, 0x4A1166a659A55625345e9515b32adECea5547C38);
        s[31] = FeedSpec("TSM", TSM_USD.FEED, TSM_USD.HEARTBEAT, 0x874cF94aa8eC88Fd9560094dD065f2fB3E41Fc2F);
        s[32] = FeedSpec("USO", USO_USD.FEED, USO_USD.HEARTBEAT, 0x75a9c76Ef439e2C7c2E5a34Ab105EcFe3766431c);
        s[33] = FeedSpec("USDG", USDG_USD.FEED, USDG_USD.HEARTBEAT, 0x61B7e5650328764B076A108EFF5fa7282a1B9aD2);
    }
}
