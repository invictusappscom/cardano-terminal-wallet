#!/bin/bash
PROJECT_PATH=
if [ -n "$ROOT_DIR" ]; then
PROJECT_PATH=$ROOT_DIR/
fi

source ${PROJECT_PATH}.env

ADDR=$1
if [ -z "$ADDR" ];then
    echo ""

    read -p "Enter address: " ADDR
fi

set -e

echo "Balance for address: $ADDR"

${CARDANO_CLI_PATH} query utxo $NETWORK --address $ADDR