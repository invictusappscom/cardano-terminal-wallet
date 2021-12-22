#!/bin/bash

source .env

echo "Existing wallets:"
ls -1 output
echo ""

read -p "Wallet name from list: " WALLET
set -e

DIR="output/$WALLET"
MY_ADDR=$(cat $DIR/payment.addr)
CHANGE_ADDR=$MY_ADDR
LOVELACE=1400000

read -p "Enter token name: " TOKEN_NAME
read -p "Enter amount of token amount: " TOKEN_AMOUNT

DIR_POLICY=$DIR/policy
DIR_TOKEN="$DIR_POLICY/tokens/$TOKEN_NAME"
mkdir -p $DIR_TOKEN

if [ ! -f $DIR_POLICY/policy.vkey ]; then
    # Create policy keys
    ${CARDANO_CLI_PATH} address key-gen \
    --verification-key-file $DIR_POLICY/policy.vkey \
    --signing-key-file $DIR_POLICY/policy.skey
fi

POLICY_VKEY_HASH=$(${CARDANO_CLI_PATH} address key-hash --payment-verification-key-file $DIR_POLICY/policy.vkey)
POLICY_SCRIPT=$DIR_TOKEN/token_policy.script

# Create policy script
cat << EOF > $POLICY_SCRIPT
{
    "type": "all",
    "scripts": [
        {
            "keyHash": "$POLICY_VKEY_HASH",
            "type": "sig"
        }
    ]
}
EOF

# Create policy id
${CARDANO_CLI_PATH} transaction policyid --script-file $DIR_TOKEN/token_policy.script > $DIR_TOKEN/policy.id
POLICY_ID=$(cat $DIR_TOKEN/policy.id)
TOKEN_META=$DIR_TOKEN/token_meta.json

# Create metadata
cat << EOF > $TOKEN_META
{
    "721": {
        "$POLICY_ID": {
        "$TOKEN_NAME": {
            "image": "ipfs://QmQFWhEM8qXAcdn879a5a4eK9aRNwTJDuEwA8URRUDjYk9",
            "name": "$TOKEN_NAME"
            }
        }
    }
}
EOF


${CARDANO_CLI_PATH} query utxo $NETWORK --address $MY_ADDR

read -p "Enter UTxO from above list: " MY_UTXO
read -p "Enter recepient address: " RCPT_ADDR

# --metadata-json-file $TOKEN_META \
## Build tx from address
echo "Building Mint Tx ..."
${CARDANO_CLI_PATH} transaction build \
--alonzo-era \
--tx-in $MY_UTXO \
--tx-out $RCPT_ADDR+$LOVELACE+"$TOKEN_AMOUNT $POLICY_ID.$TOKEN_NAME" \
--mint="$TOKEN_AMOUNT $POLICY_ID.$TOKEN_NAME" \
--mint-script-file $POLICY_SCRIPT \
--metadata-json-file $TOKEN_META \
--tx-in-collateral $MY_UTXO \
--change-address $CHANGE_ADDR \
$NETWORK \
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