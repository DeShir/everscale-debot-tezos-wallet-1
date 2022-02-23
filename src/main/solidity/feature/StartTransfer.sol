pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../lib/_all.sol";
import "../wallet/_all.sol";

abstract contract StartTransfer is StateMachine, TezosWallet {
    using TezosJSON for JsonLib.Value;
    using TezosJSON for TezosJSON.Transaction;
    using JsonLib for JsonLib.Value;
    using Net for string;

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

    TezosTransactionInfo private transaction_info;

    function requestConfirmation() internal {
        start_transaction(walletData.wallet_address, walletData.current_transfer.target_address,
            walletData.current_transfer.amount, walletData.current_transfer.fee, walletData.sing_box_handle);
    }

    function start_transaction(string from, string to, uint128 amount, uint128 fee, uint32 sing_box_handle) public {
        transaction_info = TezosTransactionInfo(from, to, amount, fee, "", "", 0, "", "", sing_box_handle, 3);
        string url;
        url = Net.tezosUrl("/chains/main/blocks/head/header");
        url.get(tvm.functionId(header_callback));
        url = Net.tezosUrl("/chains/main/blocks/head/metadata");
        url.get(tvm.functionId(metadata_callback));
        url = Net.tezosUrl("/chains/main/blocks/head/context/contracts/" + from);
        url.get(tvm.functionId(wallet_callback));
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
        transaction_info.branch = obj.hash().get();
        transaction_info.count -= 1;
        check_preparing_is_complete();
    }

    function parse_protocol_callback(bool result, JsonLib.Value obj) public {
        transaction_info.protocol = obj.nextProtocol().get();
        transaction_info.count -= 1;
        check_preparing_is_complete();
    }

    function parse_wallet_callback(bool result, JsonLib.Value obj) public {
        transaction_info.counter = obj.counter().get();
        transaction_info.count -= 1;
        check_preparing_is_complete();
    }

    function check_preparing_is_complete() private {
        if(transaction_info.count == 0) {
            forge_transaction();
        }
    }

    function forge_transaction() private {
        string url = Net.tezosUrl("/chains/main/blocks/head/helpers/forge/operations");

        TezosJSON.Transaction transaction = TezosJSON.Transaction(transaction_info.branch, transaction_info.source,
                                                transaction_info.target, transaction_info.amount,
                                                transaction_info.fee, transaction_info.counter);


        url.post(tvm.functionId(forge_transaction_callback), transaction.forgeTransactionRequest());
    }

    function forge_transaction_callback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parse_forge_callback), content);
    }

    function parse_forge_callback(bool result, JsonLib.Value obj) public {
        if(obj.as_string().hasValue()) {
            transaction_info.transaction_hex = obj.as_string().get();
            ConfirmInput.get(tvm.functionId(confirm_transaction), format("Confirm transaction. Transfer {} xtz, (fee = {} xtz) from {}, to {}",
                transaction_info.amount / 1000000.0, transaction_info.fee / 1000000.0, transaction_info.source, transaction_info.target));
        } else {
            send(Event.Done);
        }
    }

    function confirm_transaction(bool value) public {
        // todo if transaction is not confirmed sm should be moved to wallet initialized state
        if(value) {
            string url = Net.helperUrl("/hash/blake/" + "03" + transaction_info.transaction_hex);
            url.get(tvm.functionId(confirm_transaction_handler));
        } else {
            send(Event.Done);
        }
    }

    function confirm_transaction_handler(int32 statusCode, string[] retHeaders, string content) public {
        Sdk.signHash(tvm.functionId(sign_handler), transaction_info.sing_box_handle, uint256(stoi("0x" + content).get()));
    }

    function sign_handler(bytes signature) public {
        Hex.encode(tvm.functionId(save_sign), signature);
    }

    function save_sign(string hexstr) public {
        string url = Net.tezosUrl("/injection/operation");
        transaction_info.transaction_sign = hexstr;
        url.post(tvm.functionId(inject_callback), "\"" + transaction_info.transaction_hex + hexstr + "\"");
    }

    function inject_callback(int32 statusCode, string[] retHeaders, string content) public {
        send(Event.Done);
    }
}