pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputSecret is StateMachine, TezosWallet {

    function requestSecret() internal {
        SigningBoxInput.get(tvm.functionId(requestSecretCallback), "Provide your secret:", new uint256[](0));

    }

    function requestSecretCallback(uint32 handle) public {
        walletData.singBoxHandle = handle;
        send(Event.Done);
    }
}
