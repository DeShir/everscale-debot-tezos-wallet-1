pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";

library OptionalJSON {
    using JsonLib for JsonLib.Value;
    using JsonLib for mapping(uint256 => TvmCell);

    function key(JsonLib.Value value, string path) internal returns (optional(JsonLib.Value)) {
        optional(JsonLib.Value) result;
        if(value.as_object().hasValue()) {
            mapping(uint256 => TvmCell) object = value.as_object().get();
            result = object.get(path);
        }
        return result;
    }

    function asString(optional(JsonLib.Value) value) internal returns (optional(string)) {
        optional(string) result;
        if(value.hasValue()) {
            result = value.get().as_string();
        }
        return result;
    }

    function toInteger(optional(string) value) internal returns (optional(int)) {
        optional(int) result;
        if(value.hasValue()) {
            result = stoi(value.get());
        }
        return result;
    }
}
