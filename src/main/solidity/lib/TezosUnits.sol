pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "./OptionalJSON.sol";

library TezosUnits {
    function xtz(int mutez) pure internal returns(fixed) {
        return fixed(mutez) / 1000000.0;
    }
}