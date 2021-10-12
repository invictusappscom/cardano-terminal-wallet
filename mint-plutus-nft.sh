#!/bin/bash

source .env

echo "Existing wallets:"
ls -1 output
echo ""

read -p "Wallet name from list: " WALLET
set -e
# WALLET=zarko

DIR="output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
LOVELACE=1400000

read -p "Enter token name: " TOKEN_NAME
# TOKEN_NAME=ZarkoToken2

TOKEN_AMOUNT=1
DIR_POLICY=$DIR/policy
DIR_TOKEN="$DIR_POLICY/tokens/$TOKEN_NAME"
mkdir -p $DIR_TOKEN

if [ ! -f $DIR_POLICY/policy.vkey ]; then
    # Create policy keys
    ${CARDANO_CLI_PATH} address key-gen \
    --verification-key-file $DIR_POLICY/policy.vkey \
    --signing-key-file $DIR_POLICY/policy.skey
fi

# POLICY_VKEY_HASH=$(${CARDANO_CLI_PATH} address key-hash --payment-verification-key-file $DIR_POLICY/policy.vkey)
POLICY_SCRIPT=plutus/nft-mint-policy.plutus

# Create policy id
${CARDANO_CLI_PATH} transaction policyid --script-file $POLICY_SCRIPT > $DIR_TOKEN/policy.id
POLICY_ID=$(cat $DIR_TOKEN/policy.id)
TOKEN_META=$DIR_TOKEN/token_meta.json

# Create metadata
cat << EOF > $TOKEN_META
{
    "721": {
        "$POLICY_ID": {
        "$TOKEN_NAME": {
            "image": "ipfs://QmQFWhEM8qXAcdn879a5a4eK9aRNwTJDuEwA8URRUDjYk9",
            "name": "$TOKEN_NAME",
            "artist": "Picasso",
            "description": "The newest and most amazing NFT",
            "characteristics":["cool", "awesome"]
            }
        }
    }
}
EOF


${CARDANO_CLI_PATH} query utxo $NETWORK --address $MY_ADDR

read -p "Enter UTxO from above list: " MY_UTXO
read -p "Enter recepient address: " RCPT_ADDR

# Debug
#MY_UTXO=331d8270a333b296e13142b7eb015fac54136ce7233be8b51ef18730a4791530#0
#RCPT_ADDR=addr_test1qqp6z9xneafqp0ndrxgyjd3qecs4tf6ktqhvj2hyc5efg2gzq5lqcm6rfuv6yp0mtsgc2qxvwlwr938qk2nue0rqg6rqxewe52

${CARDANO_CLI_PATH} query protocol-parameters $NETWORK --out-file protocol.json


#cardano-cli transaction hash-script-data --script-data-value $MY_UTXO > $DIR_TOKEN/hash.txt

## Build tx from address
echo "Building Mint Tx ..."

${CARDANO_CLI_PATH} transaction build \
  --alonzo-era \
  $NETWORK \
  --tx-in $MY_UTXO \
  --tx-in-collateral $MY_UTXO \
  --tx-out $RCPT_ADDR+$LOVELACE+"$TOKEN_AMOUNT $POLICY_ID.$TOKEN_NAME" \
  --mint="$TOKEN_AMOUNT $POLICY_ID.$TOKEN_NAME" \
  --mint-script-file $POLICY_SCRIPT \
  --mint-redeemer-value '0' \
  --change-address $CHANGE_ADDR \
  --protocol-params-file protocol.json \
  --out-file tx.build
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