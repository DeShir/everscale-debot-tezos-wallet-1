pragma ton-solidity >= 0.53.0;

struct TezosTransfer {
    string destinationAddress;
    uint128 amount;
    uint128 fee;
}

struct WalletData {
    string walletAddress;
    uint32 singBoxHandle;
    TezosTransfer currentTransfer;
}

abstract contract TezosWallet {
    WalletData internal walletData;
}
