#!/bin/bash
ROOT_DIR=../..

# Create policy for LT
LT_TOKEN_NAME=POOLADAR4
. utils/create-policy.sh $LT_TOKEN_NAME 
NFTPOOL_TOKEN_NAME=POOLNFT4

# Env
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)
echo "Script address: $SCRIPT_ADDR"
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${SCRIPT_ADDR:0:64}'","'${SCRIPT_ADDR:64}'"]')
echo "Datum hash: $DATUM_HASH"

# Choose which LP to update
echo "Liquidity Pool on Script Address (has script address of datum hash):"
printf '%.s─' $(seq 1 $(tput cols))
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep $DATUM_HASH
read -p "Enter existin utxo for update: " EXISTING_POOL_UTXO
echo ""

# Show wallet
. $ROOT_DIR/balance-addr.sh $MY_ADDR

# Input amount of ADA + RTOKEN
echo "Creating Liquidity Pool..."
read -p "Enter amount of ADA: " ADAPOOL_VALUE
read -p "Enter amount of RTOKEN: " RTOKENPOOL_VALUE
read -p "Enter amount of RTOKEN for change: " CHANGE_RTOKENPOOL_VALUE
read -p "Enter RTOKEN PolicyID.Name: " RTOKENPOOL_POLICY_ID_NAME
read -p "Enter one or more UTxOs from above list (space separated, last will used as collateral so make sure there is only ada): " MY_UTXOS

# Mint Liquidity Pool Tokens (LT) to get in return: LT = round(sqrt(ADA*RTOKEN))
LT_TOKEN_VALUE=$(echo $ADAPOOL_VALUE $RTOKENPOOL_VALUE | /usr/bin/awk '{print int(sqrt($1*$2))}')
echo "Token amount: $LT_TOKEN_VALUE"
LOVELACE=2500000

# Format all input tx
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

CURR_RTOKENPOOL_VALUE=500
CURR_ADAPOOL_VALUE=123000111
CURR_POOLADAR_VALUE=247992

# Mint LT (POOLADAR) and send it to MY_ADDR, in the same transaction send ADA and RTOKEN pair to SCRIPT_ADDRESS to create LP
echo "Building Mint Tx ..."
set -x
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
--tx-in $EXISTING_POOL_UTXO \
--tx-in-script-file $SCRIPT \
--tx-in-datum-value '["'${SCRIPT_ADDR:0:64}'","'${SCRIPT_ADDR:64}'"]' \
--tx-in-redeemer-value 100 \
$TX_INS \
--tx-out $SCRIPT_ADDR+$((ADAPOOL_VALUE+CURR_ADAPOOL_VALUE))+"$((RTOKENPOOL_VALUE+CURR_RTOKENPOOL_VALUE)) $RTOKENPOOL_POLICY_ID_NAME"+"1 $POLICY_ID.$NFTPOOL_TOKEN_NAME" \
--tx-out-datum-hash $DATUM_HASH \
--tx-out $MY_ADDR+$LOVELACE\
+"$((CURR_POOLADAR_VALUE+LT_TOKEN_VALUE)) $POLICY_ID.$TOKEN_NAME"\
+"$CHANGE_RTOKENPOOL_VALUE $RTOKENPOOL_POLICY_ID_NAME" \
--mint="$LT_TOKEN_VALUE $POLICY_ID.$TOKEN_NAME" \
--mint-script-file $POLICY_SCRIPT \
--tx-in-collateral $MY_UTXO \
--change-address $MY_ADDR \
$NETWORK \
--protocol-params-file $ROOT_DIR/protocol.json \
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