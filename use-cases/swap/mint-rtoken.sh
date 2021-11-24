#!/bin/bash
ROOT_DIR=../..

# Create RTOKEN
RTOKEN_NAME=REV2
. utils/create-policy.sh $RTOKEN_NAME
RTOKEN_POLICY_ID_NAME=$POLICY_ID.$RTOKEN_NAME

# Env
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR

# Show user's wallet
. $ROOT_DIR/balance-addr.sh $MY_ADDR
read -p "Enter utxo from above list (it will used as collateral so make sure there is only ada): " MY_UTXO
read -p "Enter amount for minting RTOKEN: " RTOKEN_VALUE

# Mint RTOKEN_NAME 
echo "Building Mint Tx ..."
set -x
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
--tx-in $MY_UTXO \
--tx-out $MY_ADDR+1400000+"$RTOKEN_VALUE $RTOKEN_POLICY_ID_NAME" \
--mint="$RTOKEN_VALUE $RTOKEN_POLICY_ID_NAME" \
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