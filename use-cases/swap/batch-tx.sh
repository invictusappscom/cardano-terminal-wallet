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
echo ""

# Show wallet
# . $ROOT_DIR/balance-addr.sh $MY_ADDR
${CARDANO_CLI_PATH} query utxo $NETWORK --address $MY_ADDR
read -p "Enter UTxO from above list (it will be used as collateral): " MY_UTXO

echo "List of hashes:"
printf '%.s─' $(seq 1 $(tput cols))
# zarko
echo "zarko"
ADDR1=addr_test1qqp6z9xneafqp0ndrxgyjd3qecs4tf6ktqhvj2hyc5efg2gzq5lqcm6rfuv6yp0mtsgc2qxvwlwr938qk2nue0rqg6rqxewe52
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${ADDR1:0:64}'","'${ADDR1:64}'"]')
echo "Data: "\'[\"${ADDR1:0:64}\",\"${ADDR1:64}\"]\'
echo "Datum hash: $DATUM_HASH"
printf '%.s─' $(seq 1 $(tput cols))
# zarej
echo "zarej"
ADDR2=addr_test1qzxvxzjkpz4lqcrqse8zz3zpmxlzxcnf90p9lksjae2fl0dtqdv4srf98l7l6km72a5jlwngmvcj6xz2yv33cf8j0jdsetflek
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${ADDR2:0:64}'","'${ADDR2:64}'"]')
echo "Data: "\'[\"${ADDR2:0:64}\",\"${ADDR2:64}\"]\'
echo "Datum hash: $DATUM_HASH"
printf '%.s─' $(seq 1 $(tput cols))
# zare2
echo "zare2"
ADDR3=addr_test1qqvxdvjcrwzqskge258qwax59nmuvt0veflk8pn4mmx603zv5t38e79gj3lgmvfdm8ntr2yau5khprzyyhzvn3lx04ssxrx6mt
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${ADDR3:0:64}'","'${ADDR3:64}'"]')
echo "Data: "\'[\"${ADDR3:0:64}\",\"${ADDR3:64}\"]\'
echo "Datum hash: $DATUM_HASH"
printf '%.s─' $(seq 1 $(tput cols))
# test1
echo "test1"
ADDR3=addr_test1qp2e46x44jcrlylfxfgspkp2r464xeqr6tfl9j3u0cuw2pyl9gmg57pnyzqk3wv0d02nn45qrw65gmxd7gytwmrpdhjqf4yeyl
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${ADDR3:0:64}'","'${ADDR3:64}'"]')
echo "Data: "\'[\"${ADDR3:0:64}\",\"${ADDR3:64}\"]\'
echo "Datum hash: $DATUM_HASH"
printf '%.s─' $(seq 1 $(tput cols))
# test2
echo "test2"
ADDR3=addr_test1qz270xngvhp50nvc5cxktsuh6tf7s3sanh5gyqr4dphx6qzdvmtrj9qmssswlxaty64q9xukz3z3xecqch6hvfcn8tqq0g3wej
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${ADDR3:0:64}'","'${ADDR3:64}'"]')
echo "Data: "\'[\"${ADDR3:0:64}\",\"${ADDR3:64}\"]\'
echo "Datum hash: $DATUM_HASH"
printf '%.s─' $(seq 1 $(tput cols))
# Script
echo "script address"
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${SCRIPT_ADDR:0:64}'","'${SCRIPT_ADDR:64}'"]')
echo "Data: "\'[\"${SCRIPT_ADDR:0:64}\",\"${SCRIPT_ADDR:64}\"]\'
echo "Datum hash: $DATUM_HASH"
echo ""
echo ""
# Get list of all swap utxos
echo "Pending Swaps on Script Address:"
printf '%.s─' $(seq 1 $(tput cols))
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep Swap
echo ""
echo ""
echo "Liquidity Pool on Script Address (has script address of datum hash):"
printf '%.s─' $(seq 1 $(tput cols))
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep $DATUM_HASH
echo ""

read -p "Configure utils/batch.sh, save and press Enter"
. utils/batch.sh