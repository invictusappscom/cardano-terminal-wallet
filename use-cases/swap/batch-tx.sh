#!/bin/bash
ROOT_DIR=../..

source $ROOT_DIR/.env
. utils/choose-wallet.sh

# Envs
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)


echo "List of hashes"
# zarko
ADDR1=addr_test1qqp6z9xneafqp0ndrxgyjd3qecs4tf6ktqhvj2hyc5efg2gzq5lqcm6rfuv6yp0mtsgc2qxvwlwr938qk2nue0rqg6rqxewe52
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${ADDR1:0:64}'","'${ADDR1:64}'"]')
echo "Data: $ADDR1 = "\'[\"${ADDR1:0:64}\",\"${ADDR1:64}\"]\'
echo "Datum hash: $DATUM_HASH"
# zarej
ADDR2=addr_test1qzxvxzjkpz4lqcrqse8zz3zpmxlzxcnf90p9lksjae2fl0dtqdv4srf98l7l6km72a5jlwngmvcj6xz2yv33cf8j0jdsetflek
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${ADDR2:0:64}'","'${ADDR2:64}'"]')
echo "Data: $ADDR2 = "\'[\"${ADDR2:0:64}\",\"${ADDR2:64}\"]\'
echo "Datum hash: $DATUM_HASH"
# zare2
ADDR3=addr_test1qqvxdvjcrwzqskge258qwax59nmuvt0veflk8pn4mmx603zv5t38e79gj3lgmvfdm8ntr2yau5khprzyyhzvn3lx04ssxrx6mt
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${ADDR3:0:64}'","'${ADDR3:64}'"]')
echo "Data: $ADDR3 = "\'[\"${ADDR3:0:64}\",\"${ADDR3:64}\"]\'
echo "Datum hash: $DATUM_HASH"
# Script
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${SCRIPT_ADDR:0:64}'","'${SCRIPT_ADDR:64}'"]')
echo "Data: $SCRIPT_ADDR"
echo "Datum hash: $DATUM_HASH"
echo ""

# Get list of all swap utxos
echo "Pending Swaps on Script Address"
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep Swap
echo ""
echo "Liquidity Pool on Script Address (has script address of datum hash)"
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep $DATUM_HASH
echo ""

read -p "Configure utils/batch.sh, save and press Enter"
. utils/batch.sh