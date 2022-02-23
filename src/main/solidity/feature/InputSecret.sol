pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputSecret is StateMachine, TezosWallet {

    function requestSecret() internal {
        SigningBoxInput.get(tvm.functionId(sing_box_handle), "Provide your secret:", new uint256[](0));

    }

    function sing_box_handle(uint32 handle) public {
        walletData.sing_box_handle = handle;
        send(Event.Done);
    }
}
