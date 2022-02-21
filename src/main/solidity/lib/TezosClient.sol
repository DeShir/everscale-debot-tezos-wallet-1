pragma ton-solidity >= 0.53.0;

import "../interface/Network.sol";
import "../interface/Terminal.sol";
import "../interface/Json.sol";
import "../interface/ConfirmInput.sol";
import "../interface/Sdk.sol";
import "../interface/Hex.sol";

abstract contract TezosClient {

    using JsonLib for JsonLib.Value;
    using JsonLib for mapping(uint256 => TvmCell);

    function balance(string value) public {
        string[] headers;
        string host = "https://rpc.hangzhounet.teztnets.xyz";
        string url = host + "/chains/main/blocks/head/context/contracts/" + value;
        headers.push("Content-Type: application/json");
        Network.get(tvm.functionId(balance_callback), url, headers);
    }

    function balance_callback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parse_balance_callback), content);
    }

    function parse_balance_callback(bool result, JsonLib.Value obj) public {
        optional(JsonLib.Value) val;
        mapping(uint256 => TvmCell) jsonObj = obj.as_object().get();
        val = jsonObj.get("balance");
        string balance_val = val.get().as_string().get();
        balance_result(balance_val);
    }

    function balance_result(string value) virtual internal;

}

    struct TezosTransactionInfo {
        string source;
        string target;
        uint128 amount;
        uint128 fee;
        string branch;
        string protocol;
        int256 counter;
        string transaction_hex;
        string transaction_sign;
        uint32 sing_box_handle;
        int count;
    }

abstract contract TezosClientTransaction {

    using JsonLib for JsonLib.Value;
    using JsonLib for mapping(uint256 => TvmCell);

    TezosTransactionInfo transaction_info;

    function start_transaction(string from, string to, uint128 amount, uint128 fee, uint32 sing_box_handle) public {
        transaction_info = TezosTransactionInfo(from, to, amount, fee, "", "", 0, "", "", sing_box_handle, 3);

        string[] headers;
        string host = "https://rpc.hangzhounet.teztnets.xyz";
        string url_header = host + "/chains/main/blocks/head/header";
        string url_metadata = host + "/chains/main/blocks/head/metadata";
        string url_wallet = host + "/chains/main/blocks/head/context/contracts/" + from;
        headers.push("Content-Type: application/json");

        Network.get(tvm.functionId(header_callback), url_header, headers);
        Network.get(tvm.functionId(metadata_callback), url_metadata, headers);
        Network.get(tvm.functionId(wallet_callback), url_wallet, headers);
    }

    function header_callback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parse_header_callback), content);
    }
    function metadata_callback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parse_protocol_callback), content);
    }
    function wallet_callback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parse_wallet_callback), content);
    }

    function parse_header_callback(bool result, JsonLib.Value obj) public {
        optional(JsonLib.Value) val;
        mapping(uint256 => TvmCell) jsonObj = obj.as_object().get();
        val = jsonObj.get("hash");
        string hash = val.get().as_string().get();
        transaction_info.branch = hash;
        transaction_info.count -= 1;
        check_preparing_is_complete();
    }

    function parse_protocol_callback(bool result, JsonLib.Value obj) public {
        optional(JsonLib.Value) val;
        mapping(uint256 => TvmCell) jsonObj = obj.as_object().get();
        val = jsonObj.get("next_protocol");
        string next_protocol = val.get().as_string().get();
        transaction_info.protocol = next_protocol;
        transaction_info.count -= 1;
        check_preparing_is_complete();
    }

    function parse_wallet_callback(bool result, JsonLib.Value obj) public {
        optional(JsonLib.Value) val;
        mapping(uint256 => TvmCell) jsonObj = obj.as_object().get();
        val = jsonObj.get("counter");
        string counter = val.get().as_string().get();
        transaction_info.counter = stoi(counter).get();
        transaction_info.count -= 1;
        check_preparing_is_complete();
    }

    function check_preparing_is_complete() private {
        if(transaction_info.count == 0) {
            forge_transaction();
        }
    }

    function forge_transaction() private {
        string[] headers;
        string host = "https://rpc.hangzhounet.teztnets.xyz";
        string url_forge = host + "/chains/main/blocks/head/helpers/forge/operations";
        headers.push("Content-Type: application/json");


        string transaction = "{\"kind\":\"transaction\",\"source\":\""
            + transaction_info.source + "\",\"destination\":\"" + transaction_info.target + "\",\"fee\":\"" +
            format("{}", transaction_info.fee) + "\",\"counter\":\"" + format("{}", transaction_info.counter + 1) + "\",\"gas_limit\":\"1040000\",\"storage_limit\":\"60000\",\"amount\":\""
            + format("{}", transaction_info.amount) + "\"}";
        string body = "{\"branch\":\"" + transaction_info.branch + "\",\"contents\":[" + transaction + "]}";

        Network.post(tvm.functionId(forge_transaction_callback), url_forge, headers, body);
    }

    function forge_transaction_callback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parse_forge_callback), content);
    }

    function parse_forge_callback(bool result, JsonLib.Value obj) public {
        string forge =  obj.as_string().get();
        transaction_info.transaction_hex = forge;
        ConfirmInput.get(tvm.functionId(confirm_transaction), format("Confirm transaction. Transfer {} xtz, (fee = {} xtz) from {}, to {}",
        transaction_info.amount / 1000000.0, transaction_info.fee / 1000000.0, transaction_info.source, transaction_info.target));
    }

    function confirm_transaction(bool value) public {
        // todo if transaction is not confirmed sm should be moved to wallet initialized state
        if(value) {
            string[] headers;
            string host = "https://tezos-debot-helper.herokuapp.com";
            string url = host + "/hash/blake/" + "03" + transaction_info.transaction_hex;
            headers.push("Content-Type: application/json");
            Network.get(tvm.functionId(confirm_transaction_handler), url, headers);
        } else {
            transaction_done("");
        }
    }

    function confirm_transaction_handler(int32 statusCode, string[] retHeaders, string content) public {
        Sdk.signHash(tvm.functionId(sign_handler), transaction_info.sing_box_handle, uint256(stoi("0x" + content).get()));
    }

    function sign_handler(bytes signature) public {
        Hex.encode(tvm.functionId(save_sign), signature);
    }

    function save_sign(string hexstr) public {

        transaction_info.transaction_sign = hexstr;

        string[] headers;
        string host = "https://rpc.hangzhounet.teztnets.xyz";
        string url_inject = host + "/injection/operation";
        headers.push("Content-Type: application/json");
        string body = transaction_info.transaction_hex + hexstr;
        Network.post(tvm.functionId(inject_callback), url_inject, headers, "\"" + body + "\"");
    }

    function inject_callback(int32 statusCode, string[] retHeaders, string content) public {
        transaction_done(content);
    }

    function transaction_done(string operation_hash) public virtual;
}
