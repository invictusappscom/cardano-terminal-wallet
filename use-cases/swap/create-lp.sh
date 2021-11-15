#!/bin/bash
ROOT_DIR=../..

# Create policy for LT
LT_TOKEN_NAME=POOLADAR
. utils/create-policy.sh $LT_TOKEN_NAME 

# Env
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)
echo "Script address: $SCRIPT_ADDR"
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${SCRIPT_ADDR:0:64}'","'${SCRIPT_ADDR:64}'"]')
echo "Datum hash: $DATUM_HASH"

# Show wallet
. $ROOT_DIR/balance-addr.sh $MY_ADDR

# Input amount of ADA + RTOKEN
echo "Creating Liquidity Pool..."
read -p "Enter amount of ADA: " ADAPOOL_VALUE
read -p "Enter amount of RTOKEN: " RTOKENPOOL_VALUE
read -p "Enter amount of RTOKEN for change: " CHANGE_RTOKENPOOL_VALUE
read -p "Enter RTOKEN PolicyID.Name: " RTOKENPOOL_POLICY_ID_NAME
read -p "Enter one or more UTxOs from above list (space separated): " MY_UTXOS

# Mint Liquidity Pool Tokens (LT) to get in return: LT = round(sqrt(ADA*RTOKEN))
POOL_TOKEN_AMOUNT=$(echo $ADAPOOL_VALUE $RTOKENPOOL_VALUE | /usr/bin/awk '{print int(sqrt($1*$2))}')
echo "Token amount: $POOL_TOKEN_AMOUNT"
LOVELACE=2500000

# Format all input tx
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

# Mint LT (POOLADAR) and send it to MY_ADDR, in the same transaction send ADA and RTOKEN pair to SCRIPT_ADDRESS to create LP
echo "Building Mint Tx ..."
set -x
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
$TX_INS \
--tx-out $SCRIPT_ADDR+$ADAPOOL_VALUE+"$RTOKENPOOL_VALUE $RTOKENPOOL_POLICY_ID_NAME" \
--tx-out-datum-hash $DATUM_HASH \
--tx-out $MY_ADDR+$LOVELACE+"$POOL_TOKEN_AMOUNT $POLICY_ID.$TOKEN_NAME"+"$CHANGE_RTOKENPOOL_VALUE $RTOKENPOOL_POLICY_ID_NAME"+"9705 d9a1156d008866951090923bb1d39587aaebb342c50e5fb848f5d84f.SwapToken"+"5656854 d9a1156d008866951090923bb1d39587aaebb342c50e5fb848f5d84f.POOLADAR" \
--mint="$POOL_TOKEN_AMOUNT $POLICY_ID.$TOKEN_NAME" \
--mint-script-file $POLICY_SCRIPT \
--tx-in-collateral $MY_UTXO \
--change-address $MY_ADDR \
$NETWORK \
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
# Send ADA + RTOKEN to the Script address, add in Datum address of script, in return receive LT token