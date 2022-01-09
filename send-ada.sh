#!/bin/bash

source .env

echo "Existing wallets:"
ls -1 output
echo ""
read -p "Wallet name from list: " WALLET
set -e

DIR="output/$WALLET"
MY_ADDR=$(cat $DIR/payment-0.addr)
CHANGE_ADDR=$MY_ADDR

${CARDANO_CLI_PATH} query utxo $NETWORK --address $MY_ADDR

read -p "Enter one or more UTxOs from above list (space separated): " MY_UTXOS
read -p "Enter recepient address: " RCPT_ADDR
read -p "Enter amount of lovelace: " LOVELACE
read -p "Enter amount of tokens and policy id for change (for no change just Enter): " CHANGE_TOKEN_VALUE

# Format all input tx
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

# Format ouput tx
TX_OUTS=(--tx-out $RCPT_ADDR+$LOVELACE)
if [ ! -z $CHANGE_TOKEN_VALUE ]; then
 TX_OUT_CHANGE=(--tx-out $CHANGE_ADDR+1400000+"$CHANGE_TOKEN_VALUE")
fi

## Build tx from address
set -x
echo "Building Tx ..."
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
$TX_INS \
"${TX_OUTS[@]}" "${TX_OUT_CHANGE[@]}" \
--change-address $CHANGE_ADDR \
$NETWORK \
--out-file tx.build
echo "Done."

# Sign tx
echo "Sign Tx ..."
${CARDANO_CLI_PATH} transaction sign \
--signing-key-file $DIR/payment-0.skey \
--tx-body-file tx.build \
--out-file tx.sign
echo "Done."

# Submit tx
echo "Submiting Tx ..."
#${CARDANO_CLI_PATH} transaction submit $NETWORK --tx-file tx.sign

TX_ID=$(${CARDANO_CLI_PATH} transaction txid --tx-file tx.sign)

echo "Transaction Id"
echo "https://testnet.cardanoscan.io/transaction/$TX_ID"