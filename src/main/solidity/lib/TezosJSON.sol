pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "./OptionalJSON.sol";

library TezosJSON {
    using OptionalJSON for JsonLib.Value;
    using OptionalJSON for optional(JsonLib.Value);
    using OptionalJSON for optional(string);
    using JsonLib for JsonLib.Value;
    using JsonLib for mapping(uint256 => TvmCell);

    // {"balance":"1000", ...}
    function balance(JsonLib.Value value) internal returns (optional(int)) {
        optional(JsonLib.Value) jsonValue = value.key("balance");
        optional(string) strValue = jsonValue.asString();
        return strValue.toInteger();
    }

    // {"counter":"1000", ...}
    function counter(JsonLib.Value value) internal returns (optional(int)) {
        optional(JsonLib.Value) jsonValue = value.key("counter");
        optional(string) strValue = jsonValue.asString();
        return strValue.toInteger();
    }

    // {...,"hash":"B...",...}
    function hash(JsonLib.Value value) internal returns (optional(string)) {
        optional(JsonLib.Value) jsonValue = value.key("hash");
        return jsonValue.asString();
    }

    // {...,"next_protocol":"P...",...}
    function nextProtocol(JsonLib.Value value) internal returns (optional(string)) {
        optional(JsonLib.Value) jsonValue = value.key("next_protocol");
        return jsonValue.asString();
    }

    function forgeTransactionRequest(string branch, string source, string destination, uint128 amount, uint128 fee, int256 counter) internal returns (string) {
        return "{"
                + "\"branch\":\"" + branch + "\","
                + "\"contents\":["
                +   "{"
                +       "\"kind\":\"transaction\","
                +       "\"source\":\"" + source + "\","
                +       "\"destination\":\"" + destination + "\","
                +       "\"fee\":\"" + format("{}", fee) + "\","
                +       "\"counter\":\"" + format("{}", counter + 1) + "\","
                +       "\"gas_limit\":\"1040000\", "
                +       "\"storage_limit\":\"60000\","
                +       "\"amount\":\"" + format("{}", amount) + "\""
                +   "}"
                + "]}";
    }
}
