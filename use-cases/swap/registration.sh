#!/bin/bash

ROOT_DIR=../..

. utils/create-policy.sh

${CARDANO_CLI_PATH} query utxo $NETWORK --address $MY_ADDR
read -p "Enter UTxO from above list: " MY_UTXO

LOVELACE=2000000
TOKEN_AMOUNT=10005

## Build tx from address
set -x
echo "Building Mint Tx ..."
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
--tx-in $MY_UTXO \
--tx-out $MY_ADDR+$LOVELACE+"$TOKEN_AMOUNT $POLICY_ID.$TOKEN_NAME" \
--mint="$TOKEN_AMOUNT $POLICY_ID.$TOKEN_NAME" \
--mint-script-file $POLICY_SCRIPT \
--tx-in-collateral $MY_UTXO \
--change-address $MY_ADDR \
$NETWORK \
--out-file tx.build
set +x
echo "Done."

# Sign tx
echo "Sign Tx ..."
${CARDANO_CLI_PATH} transaction sign \
--signing-key-file $DIR/payment.skey \
--signing-key-file $DIR_POLICY/policy.skey \
--tx-body-file tx.build \
--out-file tx.sign
echo "Done."

# Submit tx
echo "Submiting Tx ..."
${CARDANO_CLI_PATH} transaction submit $NETWORK --tx-file tx.sign