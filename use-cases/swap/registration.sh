#!/bin/bash

# During registration process a user mints SwapToken which can use later for swap requests

# Envs
## How much SwapTokens will user receive
SWAPTOKEN_VALUE=100000000000
## How much ADA will be sent together with SwapToken
LOVELACE=2000000
ROOT_DIR=../..

SWAP_TOKEN_NAME=SwapToken
. utils/create-policy.sh $SWAP_TOKEN_NAME
SWAPTOKEN_POLICY_ID_NAME=$POLICY_ID.$SWAP_TOKEN_NAME

# Show user wallet
. $ROOT_DIR/balance-addr.sh $MY_ADDR
read -p "Enter UTxO from above list to use as collateral (make sure that have only ADA): " MY_UTXO

# Build tx
set -x
echo "Building Tx ..."
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
--tx-in $MY_UTXO \
--tx-out $MY_ADDR+$LOVELACE+"$SWAPTOKEN_VALUE $SWAPTOKEN_POLICY_ID_NAME" \
--mint="$SWAPTOKEN_VALUE $SWAPTOKEN_POLICY_ID_NAME" \
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