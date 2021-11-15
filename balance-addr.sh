#!/bin/bash
PATH=
if [ -n "$ROOT_DIR" ]; then
PATH=$ROOT_DIR/
fi

source ${PATH}.env

ADDR=$1
if [ -z "$ADDR" ];then
    echo ""

    read -p "Enter address: " ADDR
fi

set -e

echo "Balance for address: $ADDR"

${CARDANO_CLI_PATH} query utxo $NETWORK --address $ADDR