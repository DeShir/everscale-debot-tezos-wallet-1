pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";
import "../lib/_all.sol";

abstract contract MakeTransfer is StateMachine, TezosWallet {
    using TezosJSON for JsonLib.Value;
    using JsonLib for JsonLib.Value;
    using Net for string;
    using TezosUnits for int;

    string private branch;
    string private destination;
    uint128 private amount;
    uint128 private fee;
    int256 private counter;

    int private countTezosInformationRequests;
    string private forgeTransactionData;

    function inputTransferData() internal {
        Terminal.input(tvm.functionId(requestDestinationAddressCallback), "Please input  target Tezos Wallet Address:", false);
    }

    function requestDestinationAddressCallback(string value) public {
        destination = value;
        AmountInput.get(tvm.functionId(requestTransferAmountCallback), "Enter amount:",  6, 0, 1000e6);
    }

    function requestTransferAmountCallback(uint128 value) public {
        amount = value;
        AmountInput.get(tvm.functionId(requestTransferFeeCallback), "Enter fee:",  6, 0, 1000e6);
    }

    function requestTransferFeeCallback(uint128 value) public {
        fee = value;
        countTezosInformationRequests = 2;
        string url;
        url = Net.tezosUrl("/chains/main/blocks/head/header");
        url.get(tvm.functionId(requestHeaderCallback));
        url = Net.tezosUrl("/chains/main/blocks/head/context/contracts/" + walletData.walletAddress);
        url.get(tvm.functionId(requestContractCallback));
    }

    function requestHeaderCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseHeaderCallback), content);
    }

    function requestContractCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseCounterCallback), content);
    }

    function parseHeaderCallback(bool result, JsonLib.Value obj) public {
        branch = obj.hash().get();
        countTezosInformationRequests -= 1;
        isRequestedDataCompleted();
    }

    function parseCounterCallback(bool result, JsonLib.Value obj) public {
        counter = obj.counter().get();
        countTezosInformationRequests -= 1;
        isRequestedDataCompleted();
    }

    function isRequestedDataCompleted() private {
        if(countTezosInformationRequests == 0) {
            requestTransactionForge();
        }
    }

    function requestTransactionForge() private {
        string url = Net.tezosUrl("/chains/main/blocks/head/helpers/forge/operations");
        url.post(tvm.functionId(requestTransactionForgeCallback),
            TezosJSON.forgeTransactionRequest(branch, walletData.walletAddress, destination, amount, fee, counter));
    }

    function requestTransactionForgeCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseTransactionForgeCallback), content);
    }

    function parseTransactionForgeCallback(bool result, JsonLib.Value obj) public {
        if(obj.as_string().hasValue()) {
            forgeTransactionData = obj.as_string().get();
            ConfirmInput.get(tvm.functionId(confirmTransactionCallback),
                format("Confirm transaction. Transfer {} xtz, (fee = {} xtz) from {}, to {}",
                amount.xtz(), fee.xtz(),
                walletData.walletAddress, destination));
        } else {
            send(Event.Done);
        }
    }

    function confirmTransactionCallback(bool value) public {
        if(value) {
            string url = Net.helperUrl("/hash/blake/" + "03" + forgeTransactionData);
            url.get(tvm.functionId(blakeTransactionCallback));
        } else {
            send(Event.Done);
        }
    }

    function blakeTransactionCallback(int32 statusCode, string[] retHeaders, string content) public {
        Sdk.signHash(tvm.functionId(signTransactionCallback), walletData.singBoxHandle, uint256(stoi("0x" + content).get()));
    }

    function signTransactionCallback(bytes signature) public {
        Hex.encode(tvm.functionId(injectTransaction), signature);
    }

    function injectTransaction(string hexstr) public {
        string url = Net.tezosUrl("/injection/operation");
        url.post(tvm.functionId(injectTransactionCallback), "\"" + forgeTransactionData + hexstr + "\"");
    }

    function injectTransactionCallback(int32 statusCode, string[] retHeaders, string content) public {
        send(Event.Done);
    }
}
