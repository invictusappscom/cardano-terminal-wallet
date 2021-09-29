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

read -p "Wallet Name: " WALLET

OUT="output/$WALLET"
mkdir -p "$OUT"

# Generate the ROOT private key from the recovery phrase
cardano-wallet key from-recovery-phrase Shelley < phrase-testnet.prv > $OUT/root.prv

# Generate the private and public Payment keys using the root private key for the first address
cardano-wallet key child 1852H/1815H/0H/0/0 < $OUT/root.prv > $OUT/payment.prv
cardano-wallet key public --without-chain-code < $OUT/payment.prv > $OUT/payment.pub

# Generate the signing key for the payment address
${CARDANO_CLI_PATH} key convert-cardano-address-key --shelley-payment-key \
                                            --signing-key-file $OUT/payment.prv \
                                            --out-file $OUT/payment.skey


# Generate stake keys (Not neccessery)
cardano-wallet key child 1852H/1815H/0H/2/0    < $OUT/root.prv  > $OUT/stake.prv
cardano-wallet key public --without-chain-code < $OUT/stake.prv > $OUT/stake.pub

${CARDANO_CLI_PATH} key convert-cardano-address-key --shelley-payment-key \
                                            --signing-key-file $OUT/stake.prv \
                                            --out-file $OUT/stake.skey
${CARDANO_CLI_PATH} key verification-key --signing-key-file $OUT/stake.skey \
                                 --verification-key-file $OUT/stake.vkey


# Build address (Not neccessery)
${CARDANO_CLI_PATH} address build $NETWORK \
                          --payment-verification-key $(cat $OUT/payment.pub) \
                          --stake-verification-key $(cat $OUT/stake.pub) \
                          --out-file $OUT/payment.addr

echo "Success!"