pragma ton-solidity >= 0.53.0;

struct TezosTransfer {
    string target_address;
    uint128 amount;
    uint128 fee;
}

struct WalletData {
    string wallet_address;
    uint32 sing_box_handle;
    TezosTransfer current_transfer;
}

abstract contract TezosWallet {
    WalletData internal walletData;
}
