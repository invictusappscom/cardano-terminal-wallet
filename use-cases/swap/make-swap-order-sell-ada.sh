#!/bin/bash

#source .env
ROOT_DIR=../..

. utils/create-policy.sh

DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)
echo "Script address: $SCRIPT_ADDR"

# Datum is address
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${MY_ADDR:0:64}'","'${MY_ADDR:64}'"]')
echo "Datum hash: $DATUM_HASH"

. $ROOT_DIR/balance-addr.sh $MY_ADDR
read -p "Enter amount of ADA for send: " ADA_VALUE
read -p "Enter amount of SwapToken for send: " TOKEN_VALUE
read -p "Enter amount of SwapToken for change (for no change just Enter): " CHANGE_TOKEN_VALUE
read -p "Enter one or more UTxOs from above list (space separated, must contains enough ADA and SwapToken): " MY_UTXOS

# Format all input tx
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

# Format output tx
POLICY_ID_TOKEN=${POLICY_ID}.${TOKEN_NAME}
TX_OUTS=(--tx-out $SCRIPT_ADDR+$ADA_VALUE+"$TOKEN_VALUE $POLICY_ID_TOKEN")
if [ ! -z $CHANGE_TOKEN_VALUE ]; then
 TX_OUT_CHANGE=(--tx-out $CHANGE_ADDR+1400000+"$CHANGE_TOKEN_VALUE $POLICY_ID_TOKEN")
fi

# Build tx from address
echo "Building Tx ..."
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
$TX_INS \
"${TX_OUTS[@]}" \
--tx-out-datum-hash $DATUM_HASH \
"${TX_OUT_CHANGE[@]}" \
--change-address $CHANGE_ADDR \
$NETWORK \
--out-file tx.build
set +x
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

echo "Check in 30 sec balance on script address with:"
echo "ROOT_DIR=$ROOT_DIR $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep Swap"