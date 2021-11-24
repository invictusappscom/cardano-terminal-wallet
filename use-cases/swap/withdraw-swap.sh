#!/bin/bash
ROOT_DIR=../..

SWAP_TOKEN_NAME=SwapToken
. utils/create-policy.sh $SWAP_TOKEN_NAME
SWAPTOKEN_POLICY_ID_NAME=$POLICY_ID.$SWAP_TOKEN_NAME
RTOKEN_POLICY_ID_NAME=$POLICY_ID.REV2

# Prepare script variables
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)

# Prepare user wallet variables
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
# Show user wallet
. $ROOT_DIR/balance-addr.sh $MY_ADDR
read -p "Choose utxos for collateral (if there are more then space separated): " MY_UTXOS
echo ""

# Choose utxo for withdraw
DATUM='["'${MY_ADDR:0:64}'","'${MY_ADDR:64}'"]'
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value $DATUM)
echo "Your swap requests:"
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | /usr/bin/grep $DATUM_HASH
read -p "Enter utxo for withdraw: " EXISTING_POOL_UTXO
read -p "Enter total amount of SwapTokens: " SWAPTOKENPOOL_VALUE
read -p "Enter total amount of RTOKEN (for none just Enter): " RTOKENPOOL_VALUE

if [ -n "$RTOKENPOOL_VALUE" ]; then
  # Withdraw RTOKEN also with ADA and SwapToken
  TX_OUTS=(--tx-out $MY_ADDR+2000000+"$RTOKENPOOL_VALUE $RTOKEN_POLICY_ID_NAME"+"$SWAPTOKENPOOL_VALUE $SWAPTOKEN_POLICY_ID_NAME")
else
  # Just withdraw ADA and SwapToken
  TX_OUTS=(--tx-out $MY_ADDR+2000000+"$SWAPTOKENPOOL_VALUE $SWAPTOKEN_POLICY_ID_NAME")
fi

# Format all input tx
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

# Build
echo "Building Tx ..."
set -x
${CARDANO_CLI_PATH} transaction build \
  --alonzo-era \
  $NETWORK \
  --tx-in $EXISTING_POOL_UTXO \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value $DATUM \
  --tx-in-redeemer-value 1 \
  --tx-in-collateral $MY_UTXO \
  $TX_INS \
  "${TX_OUTS[@]}" \
  --protocol-params-file $ROOT_DIR/protocol.json \
  --change-address $CHANGE_ADDR \
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