pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./interface/Terminal.sol";
import "./interface/Menu.sol";
import "./interface/Network.sol";
import "./interface/Debot.sol";
import "./statemachine/StateMachine.sol";


contract TezosWallet is Debot, StateMachine {

    /// @notice Entry point function for DeBot.
    function start() public override {
        init();
        send(Event.Start, "");
    }

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns (
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Tezos Wallet Bot";
        version = "0.0.1";
        publisher = "ShiroKovka";
        caption = "";
        author = "ShiroKovka";
        support = address.makeAddrStd(0, 0xfe9a76f1a8584fbd8f092b20e917918969fc8a7b1759e9a8c15a7f907e4d72a5);
        hello = "Hello, I am a DeBot. ShiroKovka(Oba!=)";
        language = "en";
        dabi = m_debotAbi.get();
        icon = "";
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [Terminal.ID, Menu.ID, Network.ID];
    }
}
