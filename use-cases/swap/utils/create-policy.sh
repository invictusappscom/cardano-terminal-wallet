#!/bin/bash

. utils/choose-wallet.sh

TOKEN_NAME=SwapToken
if [ -n "$1" ]; then
  TOKEN_NAME=$1
fi

DIR_POLICY=./policy
DIR_TOKEN="$DIR_POLICY/tokens/$TOKEN_NAME"
mkdir -p $DIR_TOKEN

if [ ! -f $DIR_POLICY/policy.vkey ]; then
    # Create policy keys
    ${CARDANO_CLI_PATH} address key-gen \
    --verification-key-file $DIR_POLICY/policy.vkey \
    --signing-key-file $DIR_POLICY/policy.skey
fi

POLICY_SCRIPT=$DIR_TOKEN/token_policy.script
POLICY_ID_FILE=$DIR_TOKEN/policy.id
if [ ! -f $POLICY_ID_FILE ]; then
# Create policy script
echo "Creating policy script..."
POLICY_VKEY_HASH=$(${CARDANO_CLI_PATH} address key-hash --payment-verification-key-file $DIR_POLICY/policy.vkey)
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
${CARDANO_CLI_PATH} transaction policyid --script-file $POLICY_SCRIPT > $POLICY_ID_FILE
echo "Created policy with policy id: $POLICY_ID_FILE"

else
echo "Policy already present at $POLICY_ID_FILE. Nothing to do..."
fi

POLICY_ID=$(cat $POLICY_ID_FILE)
echo "PolicyId: $POLICY_ID"