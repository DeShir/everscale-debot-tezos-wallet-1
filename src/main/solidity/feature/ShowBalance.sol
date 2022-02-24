pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../lib/_all.sol";
import "../wallet/_all.sol";

abstract contract ShowBalance is StateMachine, TezosWallet {
    using TezosJSON for JsonLib.Value;
    using Net for *;

    function requestBalance() internal {
        string url = Net.tezosUrl("/chains/main/blocks/head/context/contracts/" + walletData.walletAddress);
        url.get(tvm.functionId(requestBalanceCallback));
    }

    function requestBalanceCallback(int32 statusCode, string[] retHeaders, string content) public {
        require(statusCode == 200, 101);
        Json.parse(tvm.functionId(parseBalanceCallback), content);
    }

    function parseBalanceCallback(bool result, JsonLib.Value obj) public {
        optional(int) balance = obj.balance();
        if(balance.hasValue()) {
            Terminal.print(0, format("Balance: {} xtz", fixed(balance.get()) / 1000000.0));
        } else {
            Terminal.print(0, "Something went wrong, balance didn't available.");
        }
        send(Event.Done);
    }
}
