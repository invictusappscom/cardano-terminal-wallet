#!/bin/bash

source .env

echo "Existing wallets:"
ls -1 output
echo ""

read -p "Wallet name from list: " WALLET
set -e
#WALLET=zarko

DIR="output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
SCRIPT=plutus/AlwaysSucceeds.plutus
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)
echo "Script address: $SCRIPT_ADDR"
DATUM=100
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value $DATUM)
echo "Datum hash: $DATUM_HASH"
./balance-addr.sh $MY_ADDR
read -p "Enter UTxO from above list: " MY_UTXO

LOVELACE=1400001

## Build tx from address
echo "Building Tx ..."
set -xe
${CARDANO_CLI_PATH} transaction build \
  --alonzo-era \
  $NETWORK \
  --tx-in 1d5bfe9249973e7f94ee18026945729d4b8f79bed8df542b77c7dd704b19f7d4#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value 1 \
  --tx-in-redeemer-value 1 \
  --tx-in 34c7dd3d3417acbb56d278122a492a5d86fae1443d9d738846eabebe46322ed2#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value 100 \
  --tx-in-redeemer-value 100 \
  --tx-in-collateral $MY_UTXO \
  --protocol-params-file protocol.json \
  --change-address $CHANGE_ADDR \
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