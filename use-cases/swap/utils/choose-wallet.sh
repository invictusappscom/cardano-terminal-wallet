#!/bin/bash

source $ROOT_DIR/.env

echo "Existing wallets:"
ls -1 $ROOT_DIR/output
echo ""

read -p "Wallet name from list: " WALLET
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
set -e