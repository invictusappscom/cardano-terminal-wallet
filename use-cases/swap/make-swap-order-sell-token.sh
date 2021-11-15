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
read -p "Enter RTOKEN PolicyID.Name: " RTOKEN_POLICY_ID_NAME
read -p "Enter amount of RTOKEN for send: " RTOKEN_VALUE
read -p "Enter amount of RTOKEN for change: " CHANGE_RTOKEN_VALUE
read -p "Enter amount of SwapToken for send: " SWAP_TOKEN_VALUE
read -p "Enter amount of SwapToken for change: " CHANGE_SWAP_TOKEN_VALUE
read -p "Enter one or more UTxOs from above list (space separated, must contains enough ADA and tokens): " MY_UTXOS

# Format all input tx
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

# Format output tx
ADA_VALUE=1900000
SWAPTOKEN_POLICY_ID_NAME=${POLICY_ID}.${TOKEN_NAME}
TX_OUTS=(--tx-out $SCRIPT_ADDR+$ADA_VALUE+"$SWAP_TOKEN_VALUE $SWAPTOKEN_POLICY_ID_NAME"+"$RTOKEN_VALUE $RTOKEN_POLICY_ID_NAME")
TX_OUT_CHANGE=(--tx-out $CHANGE_ADDR+$ADA_VALUE+"$CHANGE_SWAP_TOKEN_VALUE $SWAPTOKEN_POLICY_ID_NAME"+"$CHANGE_RTOKEN_VALUE $RTOKEN_POLICY_ID_NAME")

# Build tx from address
echo "Building Tx ..."
set -x
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