#!/bin/bash

source .env
set -e
if [ ! -f phrase-testnet.prv ];then
    echo "Please input seed phrase in file phrase-testnet.prv"
    touch phrase-testnet.prv
    exit 1
else
    echo "Seed phrase file present!"
fi

if [ -z "$(cat phrase-testnet.prv)" ];then
    echo "File phrase-testnet.prv is empty"
    exit 1
fi

WALLET=$1
if [ -z "$WALLET" ];then
    echo "Existing wallets:"
    ls -1 output
    echo ""

    read -p "Wallet name from list: " WALLET
fi

INDEX=$2
if [ -z "$INDEX" ];then
    echo "Existing wallets:"
    ls -1 output
    echo ""

    read -p "Enter address index m/1852H/1815H/0H/0/<index> (if you don't enter, it will be default 0): " INDEX
    if [ -z "$INDEX" ];then
        INDEX=0
    fi
fi

OUT="output/$WALLET"
mkdir -p "$OUT"

# Generate the ROOT private key from the recovery phrase
cardano-wallet key from-recovery-phrase Shelley < phrase-testnet.prv > $OUT/root.prv

# Generate the private and public Payment keys using the root private key for the first address
cardano-wallet key child 1852H/1815H/0H/0/${INDEX} < $OUT/root.prv > $OUT/payment-${INDEX}.prv
cardano-wallet key public --without-chain-code < $OUT/payment-${INDEX}.prv > $OUT/payment-${INDEX}.pub

# Generate the signing key for the payment address
${CARDANO_CLI_PATH} key convert-cardano-address-key --shelley-payment-key \
                                            --signing-key-file $OUT/payment-${INDEX}.prv \
                                            --out-file $OUT/payment-${INDEX}.skey


# Generate stake keys (Not neccessery)
cardano-wallet key child 1852H/1815H/0H/2/${INDEX}    < $OUT/root.prv  > $OUT/stake-${INDEX}.prv
cardano-wallet key public --without-chain-code < $OUT/stake.prv > $OUT/stake-${INDEX}.pub

${CARDANO_CLI_PATH} key convert-cardano-address-key --shelley-payment-key \
                                            --signing-key-file $OUT/stake-${INDEX}.prv \
                                            --out-file $OUT/stake-${INDEX}.skey
${CARDANO_CLI_PATH} key verification-key --signing-key-file $OUT/stake-${INDEX}.skey \
                                 --verification-key-file $OUT/stake-${INDEX}.vkey


# Build address (Not neccessery)
${CARDANO_CLI_PATH} address build $NETWORK \
                          --payment-verification-key $(cat $OUT/payment-${INDEX}.pub) \
                          --stake-verification-key $(cat $OUT/stake-${INDEX}.pub) \
                          --out-file $OUT/payment-${INDEX}.addr

echo "Success!"