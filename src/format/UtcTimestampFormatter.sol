// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @notice Deterministic UTC timestamp formatting for scripts/tests.
library UtcTimestampFormatter {
    /// @notice Formats a unix timestamp (seconds) as UTC "YYYY-MM-DD HH:MM:SS UTC".
    // slither-disable-next-line divide-before-multiply
    function format(uint256 timestamp) internal pure returns (string memory) {
        unchecked {
            // Date (civil_from_days, Howard Hinnant)
            uint256 z = timestamp / 86400 + 719468;
            uint256 era = z / 146097;
            uint256 doe = z - era * 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            uint256 y = yoe + era * 400;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            uint256 mp = (5 * doy + 2) / 153;
            uint256 d = doy - (153 * mp + 2) / 5 + 1;
            uint256 m = mp < 10 ? mp + 3 : mp - 9;
            if (m <= 2) y += 1;

            // Time
            uint256 secondsInDay = timestamp % 86400;
            uint256 h = secondsInDay / 3600;
            uint256 min = (secondsInDay % 3600) / 60;
            uint256 s = secondsInDay % 60;

            // "YYYY-MM-DD HH:MM:SS UTC" (23 bytes)
            bytes memory out = new bytes(23);

            out[0] = bytes1(uint8(48 + ((y / 1000) % 10)));
            out[1] = bytes1(uint8(48 + ((y / 100) % 10)));
            out[2] = bytes1(uint8(48 + ((y / 10) % 10)));
            out[3] = bytes1(uint8(48 + (y % 10)));
            out[4] = 0x2d;
            out[5] = bytes1(uint8(48 + ((m / 10) % 10)));
            out[6] = bytes1(uint8(48 + (m % 10)));
            out[7] = 0x2d;
            out[8] = bytes1(uint8(48 + ((d / 10) % 10)));
            out[9] = bytes1(uint8(48 + (d % 10)));
            out[10] = 0x20;
            out[11] = bytes1(uint8(48 + ((h / 10) % 10)));
            out[12] = bytes1(uint8(48 + (h % 10)));
            out[13] = 0x3a;
            out[14] = bytes1(uint8(48 + ((min / 10) % 10)));
            out[15] = bytes1(uint8(48 + (min % 10)));
            out[16] = 0x3a;
            out[17] = bytes1(uint8(48 + ((s / 10) % 10)));
            out[18] = bytes1(uint8(48 + (s % 10)));
            out[19] = 0x20;
            out[20] = 0x55; // U
            out[21] = 0x54; // T
            out[22] = 0x43; // C

            return string(out);
        }
    }
}
