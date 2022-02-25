pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";

abstract contract MainMenu is StateMachine {
    function showMainMenu() internal {
        Menu.select("Main menu", "", [
            MenuItem("Check Balance", "", tvm.functionId(checkBalanceItemCallback)),
            MenuItem("Change Wallet Address", "", tvm.functionId(changeWalletAddressItemCallback)),
            MenuItem("Input secret", "", tvm.functionId(requestSecretItemCallback)),
            MenuItem("Start Transaction", "", tvm.functionId(startTransactionCallback))
            ]);
    }

    function checkBalanceItemCallback(uint32 index) public {
        send(Event.RequestBalance);
    }

    function changeWalletAddressItemCallback(uint32 index) public {
        send(Event.ChangeWalletAddress);
    }

    function requestSecretItemCallback(uint32 index) public {
        send(Event.RequestSecret);
    }

    function startTransactionCallback(uint32 index) public {
        send(Event.StartTransfer);
    }
}
