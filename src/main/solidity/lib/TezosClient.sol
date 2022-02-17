pragma ton-solidity >= 0.53.0;

import "../interface/Network.sol";

struct TezosTransactionInfo {
// branch = header['hash']
//protocol = metadata['next_protocol']
//counter = account['counter']
    string branch;
    string protocol;
    string counter;
    string chain_id;
    string transaction_hex;
    string transaction_sign;
    int count;
}

//header = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/header').json()
//metadata = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/metadata').json()
//account = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/context/contracts/' + SOURCE_WALLET).json()
//chain_id = requests.get(RPC_ENDPOINT + '/chains/main/chain_id').json()


abstract contract TezosClient {
    string host = "https://rpc.hangzhounet.teztnets.xyz";

    function balance(string value) public {
        string[] headers;
        string url = host + "/chains/main/blocks/head/context/contracts/" + value + "/balance";
        headers.push("Content-Type: application/json");
        Network.get(tvm.functionId(balance_callback), url, headers);
    }

    function balance_callback(int32 statusCode, string[] retHeaders, string content) public {
        balance_result(content);
    }

    function balance_result(string value) virtual public;


    function start_transaction(string from, string to, string value, string fee) public {
        string[] headers;
        string url = host + "/chains/main/blocks/head/context/contracts/" + value + "/balance";
        headers.push("Content-Type: application/json");
        //header = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/header').json()
        //metadata = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/metadata').json()
        //account = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/context/contracts/' + SOURCE_WALLET).json()
        //chain_id = requests.get(RPC_ENDPOINT + '/chains/main/chain_id').json()

        // Network.get(tvm.functionId(balance_callback), url, headers);

    }

    function forge_transaction_callback(int32 statusCode, string[] retHeaders, string content) public {

    }
    // Transaction
    // 1.   got forge
    // 2.   sign
    // 2.1  got hash (external)
    // 2.2  sign


    //header = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/header').json()
    //metadata = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/metadata').json()
    //account = requests.get(RPC_ENDPOINT + '/chains/main/blocks/head/context/contracts/' + SOURCE_WALLET).json()
    //chain_id = requests.get(RPC_ENDPOINT + '/chains/main/chain_id').json()

}
