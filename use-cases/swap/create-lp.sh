#!/bin/bash

# Create Liquidity Pool with pair ADA/RTOKEN and send it to the Plutus Script address

ROOT_DIR=../..

# Create policy for LT
LT_TOKEN_NAME=LTPOOLADAR
. utils/create-policy.sh $LT_TOKEN_NAME 
LTTOKEN_POLICY_ID_NAME=$POLICY_ID.$LT_TOKEN_NAME
# Use the same policy for NFTPOOL
NFTPOOL_TOKEN_NAME=POOLNFT
NFTPOOLTOKEN_POLICY_ID_NAME=$POLICY_ID.$NFTPOOL_TOKEN_NAME
RTOKEN_NAME=REV2
RTOKENPOOL_POLICY_ID_NAME=$POLICY_ID.$RTOKEN_NAME

# Env
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${SCRIPT_ADDR:0:64}'","'${SCRIPT_ADDR:64}'"]')

# Show user's wallet
. $ROOT_DIR/balance-addr.sh $MY_ADDR

# Input amount of ADA + RTOKEN
echo "Creating Liquidity Pool..."
read -p "Enter amount of ADA to sent to the Pool: " ADAPOOL_VALUE
read -p "Enter amount of RTOKEN to send to the Pool: " RTOKENPOOL_VALUE
read -p "Enter amount of RTOKEN for change to go back to your address (for none just press Enter): " CHANGE_RTOKENPOOL_VALUE
## The change for native tokens at collateral utxo is not implemented so we must choose utxo that contains just ADA
read -p "Enter utxos from above list (space separated, the last one will be used as collateral so make sure that have just ADA): " MY_UTXOS

# Mint Liquidity Pool Tokens (LT) to get in return: LT = round(sqrt(ADA*RTOKEN))
LT_TOKEN_VALUE=$(echo $ADAPOOL_VALUE $RTOKENPOOL_VALUE | /usr/bin/awk '{print int(sqrt($1*$2))}')
echo "LT Token amount that will be minted: $LT_TOKEN_VALUE"
## how much ADA will be sent with minted LT_TOKEN
LOVELACE=1500000

# Generate out transaction which will be send to user's address MY_ADDR
TX_OUT_MY_ADDR=(--tx-out $MY_ADDR+$LOVELACE+"$LT_TOKEN_VALUE $LTTOKEN_POLICY_ID_NAME")
if [ -n "$CHANGE_RTOKENPOOL_VALUE" ];then
## We have change RTOKEN, we need just to add it to the end
  #TX_OUT_MY_ADDR=(--tx-out $MY_ADDR+$LOVELACE+"$LT_TOKEN_VALUE $LT_TOKEN_POLICY_ID_NAME"+"$CHANGE_RTOKENPOOL_VALUE $RTOKENPOOL_POLICY_ID_NAME")
## 2 different tx-out one for LT_TOKEN and 2nd one for RTOKEN change, this is because later we can easily select tokens for withdraw  
  TX_OUT_MY_ADDR=(--tx-out $MY_ADDR+$LOVELACE+"$LT_TOKEN_VALUE $LTTOKEN_POLICY_ID_NAME" --tx-out $MY_ADDR+$LOVELACE+"$CHANGE_RTOKENPOOL_VALUE $RTOKENPOOL_POLICY_ID_NAME")
fi

# Prepare all input utxos
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

# Mint LT_TOKEN_NAME and send it to MY_ADDR, in the same transaction send ADA and RTOKEN pair to SCRIPT_ADDRESS to create LP
echo "Building Mint Tx ..."
set -x
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
$TX_INS \
--tx-out $SCRIPT_ADDR+$ADAPOOL_VALUE+"$RTOKENPOOL_VALUE $RTOKENPOOL_POLICY_ID_NAME"+"1 $NFTPOOLTOKEN_POLICY_ID_NAME" \
--tx-out-datum-hash $DATUM_HASH \
"${TX_OUT_MY_ADDR[@]}" \
--mint="$LT_TOKEN_VALUE $LTTOKEN_POLICY_ID_NAME"+"1 $NFTPOOLTOKEN_POLICY_ID_NAME" \
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