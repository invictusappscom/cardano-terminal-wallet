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
DATUM='["addr_test1wpnlxv2xv9a9ucvnvzqakwepzl9ltx7jzgm53av2e9ncv4sysemm8",""]'
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
  --tx-in 4aacd70376e79939b7fa1389c4a1c183f66432a90fd23f2bd6c895a64c1eed8d#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value $DATUM \
  --tx-in-redeemer-value 1 \
  --tx-in-collateral $MY_UTXO \
  --tx-out $MY_ADDR+1722002+"5656854 d9a1156d008866951090923bb1d39587aaebb342c50e5fb848f5d84f.POOLADAR" \
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