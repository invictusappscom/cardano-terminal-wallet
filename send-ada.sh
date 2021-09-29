#!/bin/bash

source .env

echo "Existing wallets:"
ls -1 output
echo ""
read -p "Wallet name from list: " WALLET
set -e

DIR="output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR

${CARDANO_CLI_PATH} query utxo $NETWORK --address $MY_ADDR

read -p "Enter UTxO from above list: " MY_UTXO
read -p "Enter recepient address: " RCPT_ADDR
read -p "Enter amount of lovelace: " LOVELACE

## Build tx from address
echo "Building Tx ..."
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
--tx-in $MY_UTXO \
--tx-out $RCPT_ADDR+$LOVELACE \
--change-address $CHANGE_ADDR \
$NETWORK \
--out-file tx.build
echo "Done."

# Sign tx
echo "Sign Tx ..."
${CARDANO_CLI_PATH} transaction sign \
--signing-key-file $DIR/payment.skey \
--tx-body-file tx.build \
--out-file tx.sign
echo "Done."

# Submit tx
echo "Submiting Tx ..."
${CARDANO_CLI_PATH} transaction submit $NETWORK --tx-file tx.sign