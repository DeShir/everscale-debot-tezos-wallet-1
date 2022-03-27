pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";

library Net {
    string constant tezosHost = "https://rpc.hangzhounet.teztnets.xyz";
    string constant helperHost = "https://everscale-helper.herokuapp.com";

    function get(string url, uint32 functionId) internal {
        string[] headers;
        headers.push("Content-Type: application/json");
        Network.get(functionId, url, headers);
    }

    function post(string url, uint32 functionId, string body) internal {
        string[] headers;
        headers.push("Content-Type: application/json");
        Network.post(functionId, url, headers, body);
    }

    function tezosUrl(string path) internal pure returns (string){
        return tezosHost + path;
    }

    function helperUrl(string path) internal pure returns (string){
        return helperHost + path;
    }
}
