#!/bin/bash

source .env

echo "Existing wallets:"
ls -1 output
echo ""

read -p "Wallet name from list: " WALLET

set -e

DIR="output/$WALLET"
ADDR=$(cat $DIR/payment.addr)

echo "Balance for address: $ADDR"

${CARDANO_CLI_PATH} query utxo $NETWORK --address $ADDR