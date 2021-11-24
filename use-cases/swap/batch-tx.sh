#!/bin/bash
ROOT_DIR=../..

source $ROOT_DIR/.env
. utils/choose-wallet.sh

NFTPOOL_TOKEN_NAME=POOLNFT
# Policy id and policy script are the same for all tokens, just here in production probably not
DIR_POLICY=policy
POLICY_ID=$(cat policy/tokens/$NFTPOOL_TOKEN_NAME/policy.id)
POLICY_SCRIPT="policy/tokens/$NFTPOOL_TOKEN_NAME/token_policy.script"
NFTPOOLTOKEN_POLICY_ID_NAME=$POLICY_ID.$NFTPOOL_TOKEN_NAME
RTOKEN_POLICY_ID_NAME=$POLICY_ID.REV2
SWAPTOKEN_POLICY_ID_NAME=$POLICY_ID.SwapToken

# Envs
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)
echo ""

# Show user wallet to select utxo for collateral
${CARDANO_CLI_PATH} query utxo $NETWORK --address $MY_ADDR
read -p "Enter UTxO from above list (it will be used as collateral, make sure that has only ADA): " MY_UTXO

echo "List of hashes:"
printf '%.s─' $(seq 1 $(tput cols))

# List all wallet addresses with plain Datum (Data) which can be included in tx and also with Datum hash. 
# Datum hash is using to match request swap utxo with address on which needs to be received swap
WALLETS_DIR=$ROOT_DIR/output
WALLETS=$(ls $WALLETS_DIR)
for WALLET in $WALLETS
do
    echo "$WALLET"
    ADDR=$(cat $WALLETS_DIR/$WALLET/payment.addr)
    DATA=[\"${ADDR:0:64}\",\"${ADDR:64}\"]
    DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value $DATA)
    echo "Hash: $DATUM_HASH"
    echo "Data: $DATA"
    echo "Addr: $ADDR"
    printf '%.s─' $(seq 1 $(tput cols))
done

# Script data and hash
echo "script address"
SCRIPT_DATA=[\"${SCRIPT_ADDR:0:64}\",\"${SCRIPT_ADDR:64}\"]
SCRIPT_DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value $SCRIPT_DATA)
echo "Script Hash: $SCRIPT_DATUM_HASH"
echo "Script Data: $SCRIPT_DATA"
echo "Script Addr: $SCRIPT_ADDR"
echo ""
echo ""

# Get list of all swap requests utxos
echo "Pending Swaps on Script Address:"
printf '%.s─' $(seq 1 $(tput cols))
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep $SWAPTOKEN_POLICY_ID_NAME
echo ""
echo ""

# Beside swap requests we need liquidity pool utxo
echo "Liquidity Pool on Script Address (has script address of datum hash):"
printf '%.s─' $(seq 1 $(tput cols))
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep $SCRIPT_DATUM_HASH | grep "$NFTPOOLTOKEN_POLICY_ID_NAME "
echo ""

read -p "Configure utils/batch.sh, save and press Enter"
. utils/batch.sh