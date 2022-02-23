pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";

abstract contract MainMenu is StateMachine {
    function showMainMenu() internal {
        Menu.select("Main menu", "", [
            MenuItem("Check Balance", "", tvm.functionId(checkBalance)),
            MenuItem("Change Wallet Address", "", tvm.functionId(changeWalletAddress)),
            MenuItem("Input secret", "", tvm.functionId(requestSecretMenu)),
            MenuItem("Start Transaction", "", tvm.functionId(startTransaction))
            ]);
    }

    function checkBalance(uint32 index) public {
        send(Event.RequestBalance);
    }

    function changeWalletAddress(uint32 index) public {
        send(Event.ChangeWalletAddress);
    }

    function requestSecretMenu(uint32 index) public {
        send(Event.RequestSecret);
    }

    function startTransaction(uint32 index) public {
        send(Event.StartTransaction);
    }
}
