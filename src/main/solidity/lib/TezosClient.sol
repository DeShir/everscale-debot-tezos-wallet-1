pragma ton-solidity >=0.35.0;

import "../interface/Network.sol";

abstract contract TezosClient {
    string host = "https://rpc.hangzhounet.teztnets.xyz";

    function balance(uint32 answerId, string value) public {
        string[] headers;
        string url = host + "/chains/main/blocks/head/context/contracts/" + value + "/balance";
        headers.push("Content-Type: application/json");
        Network.get(answerId, url, headers);
    }
}
