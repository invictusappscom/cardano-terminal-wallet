#!/bin/bash

source .env

mkdir -p output
echo "Existing wallets:"
ls -1 output
echo ""

set -e
read -p "New wallet name: " WALLET

OUT="output/$WALLET"
mkdir -p "$OUT"

if [ ! -f $OUT/payment.vkey ]; then
    ${CARDANO_CLI_PATH} address key-gen \
    --verification-key-file $OUT/payment.vkey \
    --signing-key-file $OUT/payment.skey
else
    echo "Payment keys already present!"
fi

if [ ! -f $OUT/stake.vkey ]; then
${CARDANO_CLI_PATH} stake-address key-gen \
--verification-key-file $OUT/stake.vkey \
--signing-key-file $OUT/stake.skey
else
    echo "Stake keys already present!"
fi

if [ ! -f  $OUT/payment.addr ]; then
    ${CARDANO_CLI_PATH} address build \
    --payment-verification-key-file $OUT/payment.vkey \
    --stake-verification-key-file $OUT/stake.vkey \
    $NETWORK \
    --out-file $OUT/payment.addr
    echo "Address generation success!" && cat $OUT/payment.addr
else
    echo "Address already generated!. Nothing to do."   
fi