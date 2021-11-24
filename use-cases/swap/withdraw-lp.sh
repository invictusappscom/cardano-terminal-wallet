#!/bin/bash
ROOT_DIR=../..

# Create policy for LT
LT_TOKEN_NAME=LTPOOLADAR
. utils/create-policy.sh $LT_TOKEN_NAME 
LT_TOKEN_POLICY_ID_NAME=$POLICY_ID.$LT_TOKEN_NAME
NFTPOOL_TOKEN_NAME=POOLNFT
NFTPOOL_POLICY_ID_NAME=$POLICY_ID.$NFTPOOL_TOKEN_NAME
RTOKEN_NAME=REV2
RTOKEN_POLICY_ID_NAME=$POLICY_ID.$RTOKEN_NAME

# Prepare script variables
SCRIPT="$ROOT_DIR/plutus/AlwaysSucceeds.plutus"
SCRIPT_ADDR=$(${CARDANO_CLI_PATH} address build --payment-script-file $SCRIPT $NETWORK)
DATUM_HASH=$(${CARDANO_CLI_PATH} transaction hash-script-data --script-data-value '["'${SCRIPT_ADDR:0:64}'","'${SCRIPT_ADDR:64}'"]')

# Show LP utxo
echo "Liquidity Pool on Script Address (has script address of datum hash):"
printf '%.s─' $(seq 1 $(tput cols))
. $ROOT_DIR/balance-addr.sh $SCRIPT_ADDR | grep $DATUM_HASH | grep $RTOKEN_NAME
read -p "Enter utxo for withdraw: " EXISTING_POOL_UTXO
read -p "Enter total amount of ADA: " ADAPOOL_VALUE
read -p "Enter total amount of RTOKEN: " RTOKENPOOL_VALUE
echo ""

# Pripare user wallet variables
DIR="$ROOT_DIR/output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
# Show user wallet
. $ROOT_DIR/balance-addr.sh $MY_ADDR
read -p "Enter amount of LT Token: " LT_TOKEN_VALUE
# Here we need to select utxo which contains LT_TOKEN and also one utxo which will be use as collateral
read -p "Enter one or more UTxOs from above list (space separated, last will used as collateral so make sure there is only ada): " MY_UTXOS
read -p "Enter total amount of RTOKEN from selected utxo (it will be returned, if there is no RTOKEN just press enter): " RTOKEN_MY_VALUE

# Calculate total of LP Tokens (we are not store this info anywere because it can be easily calculated whenever it is required)
LT_TOKEN_TOTAL_VALUE=$(echo $ADAPOOL_VALUE $RTOKENPOOL_VALUE | /usr/bin/awk '{print int(sqrt($1*$2))}')
set -x
# Calculate return values of tokens and change
if [ $LT_TOKEN_VALUE -lt $LT_TOKEN_TOTAL_VALUE ];
then 
# do calculation
# Values that needs to go to user to MY_ADDR
ADA_RETURN_VALUE=$(/usr/bin/bc -l <<< "a=$LT_TOKEN_VALUE/$LT_TOKEN_TOTAL_VALUE*$ADAPOOL_VALUE;scale=0;a/1")
RTOKEN_RETURN_VALUE=$(/usr/bin/bc -l <<< "a=$LT_TOKEN_VALUE/$LT_TOKEN_TOTAL_VALUE*$RTOKENPOOL_VALUE;scale=0;a/1")
# Values that needs to go back to SCRIPT_ADDR as change
ADA_CHANGE_VALUE=$(/usr/bin/expr $ADAPOOL_VALUE - $ADA_RETURN_VALUE)
RTOKEN_CHANGE_VALUE=$(/usr/bin/expr $RTOKENPOOL_VALUE - $RTOKEN_RETURN_VALUE)
else 
# it is equal because cannot be more then LT_TOKEN_TOTAL_VALUE
ADA_RETURN_VALUE=$ADAPOOL_VALUE
RTOKEN_RETURN_VALUE=$RTOKENPOOL_VALUE
fi

# Add RTOKEN from user's utxo that needs to be returned as change to tx-out
RTOKEN_RETURN_VALUE=$(/usr/bin/expr $RTOKEN_RETURN_VALUE + ${RTOKEN_MY_VALUE:-0})

# Format all input tx
for MY_UTXO in $MY_UTXOS
do
    TX_INS="--tx-in $MY_UTXO $TX_INS"
done

# Separate utxo for sending minimal ada and RTOKEN the rest of ada will be sent together with chahge to user wallet
TX_OUTS=(--tx-out $MY_ADDR+1400000+"$RTOKEN_RETURN_VALUE $RTOKEN_POLICY_ID_NAME")

# Format change for script address
if [ ! -z $ADA_CHANGE_VALUE ]; then 
## make sure that we have enough ada to send native token
 if [ $ADA_CHANGE_VALUE -lt 2000000 ]; then ADA_CHANGE_VALUE=2000000; fi
 TX_OUT_CHANGE=(--tx-out $SCRIPT_ADDR+$ADA_CHANGE_VALUE+"$RTOKEN_CHANGE_VALUE $RTOKEN_POLICY_ID_NAME"+"1 $NFTPOOL_POLICY_ID_NAME" --tx-out-datum-hash $DATUM_HASH)
## Burn LT_TOKEN_VALUE so LT Tokens are spent and cannot be reused
  BURN_LT=(--mint "-$LT_TOKEN_VALUE $LT_TOKEN_POLICY_ID_NAME" --mint-script-file $POLICY_SCRIPT)
else
## Burn LT_TOKEN and NFTPOOL - this is the case when nothing left to LP so we don't need NFT also
  BURN_LT=(--mint "-$LT_TOKEN_VALUE $LT_TOKEN_POLICY_ID_NAME"+"-1 $NFTPOOL_POLICY_ID_NAME" --mint-script-file $POLICY_SCRIPT)
fi

# Build transaction
echo "Building Mint Tx ..."
set -x
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
--tx-in $EXISTING_POOL_UTXO \
--tx-in-script-file $SCRIPT \
--tx-in-datum-value '["'${SCRIPT_ADDR:0:64}'","'${SCRIPT_ADDR:64}'"]' \
--tx-in-redeemer-value 1 \
$TX_INS \
"${TX_OUTS[@]}" "${TX_OUT_CHANGE[@]}" \
"${BURN_LT[@]}" \
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