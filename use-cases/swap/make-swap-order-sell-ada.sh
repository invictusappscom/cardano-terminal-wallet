#!/bin/bash

#source .env
ROOT_DIR=../..

. utils/create-policy.sh
SWAPTOKEN_POLICY_ID_NAME=${POLICY_ID}.${TOKEN_NAME}

DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)

# Datum is address
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${MY_ADDR:0:64}'","'${MY_ADDR:64}'"]')

. $ROOT_DIR/balance-addr.sh $MY_ADDR
read -p "Enter amount of ADA for send: " ADA_VALUE
read -p "Enter amount of SwapToken for send: " SWAPTOKEN_VALUE
read -p "Enter amount of SwapToken for change (for no change just Enter): " CHANGE_SWAPTOKEN_VALUE
read -p "Enter one or more UTxOs from above list (space separated, must contains enough ADA and SwapToken): " MY_UTXOS

# Format all input tx
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

# Format output tx
TX_OUTS=(--tx-out $SCRIPT_ADDR+$ADA_VALUE+"$SWAPTOKEN_VALUE $SWAPTOKEN_POLICY_ID_NAME")
if [ ! -z $CHANGE_SWAPTOKEN_VALUE ]; then
 TX_OUT_CHANGE=(--tx-out $CHANGE_ADDR+1400000+"$CHANGE_SWAPTOKEN_VALUE $SWAPTOKEN_POLICY_ID_NAME")
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