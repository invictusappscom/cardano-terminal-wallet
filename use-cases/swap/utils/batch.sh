echo "Building Tx ..."
set -xe

POOL_UTXO=4cf7df47e1aa8303380aa4dde4b83545c48e6094fea6735a9885e9e784e6d80d#1
# SwapTokens taken from Swap Orders which goes to the script or it can be burned
SWAP_TOKENS_END_VALUE=$((10000000 + 200))
# Lovalace taken from Swap Orders which goes to the script, also fee needs to be included (after first start it will be error missing ada eg -202067)
ADA_IN=$(( 1900000  + 50000000 + 27000000 ))
ADA_OUT=$(( 10000000 + 1400000 + 14000000 + 205543 ))
LOVELACE_END_VALUE=$(($ADA_IN - $ADA_OUT))

RTOKEN_IN=$((540 + 200))
RTOKEN_OUT=200
RTOKEN_END_VALUE=$(($RTOKEN_IN - $RTOKEN_OUT))

BURN_SWAP_TOKENS=(--mint "-$SWAP_TOKENS_END_VALUE $SWAPTOKEN_POLICY_ID_NAME" --mint-script-file $POLICY_SCRIPT)
# or
SEND_SWAPTOKENS_TO_ISSUER=(--tx-out $MY_ADDR+14000000+"$SWAP_TOKENS_END_VALUE $SWAPTOKEN_POLICY_ID_NAME")

# Build Tx - in tx-out for script address needs to be send all ada just to meke sure to not go to change address since change address is address of wallet of tx issuer
${CARDANO_CLI_PATH} transaction build \
  --alonzo-era \
  $NETWORK \
  \
  --tx-in ca60ad59ae9df6b3188d9c6b8545723a973695e58dc5aab6c5edf3b6611a10b5#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1qzxvxzjkpz4lqcrqse8zz3zpmxlzxcnf90p9lksjae2fl0dtqdv4sr","f98l7l6km72a5jlwngmvcj6xz2yv33cf8j0jdsetflek"]' \
  --tx-in-redeemer-value 1 \
  --tx-out addr_test1qzxvxzjkpz4lqcrqse8zz3zpmxlzxcnf90p9lksjae2fl0dtqdv4srf98l7l6km72a5jlwngmvcj6xz2yv33cf8j0jdsetflek+10000000 \
  \
  --tx-in cea4b3f0dd6d815cc028c0f6e790bf719f49c334108ca1014e4794fc59344093#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1qrf5lmxa4zqgquzgvfwt78cf4upy4drffj0ytzyd9gx7vpzuw64zlm","7ykrpcsmf29t00vd96jpq2hywxf5t2yf84wd7sdwlrtt"]' \
  --tx-in-redeemer-value 100 \
  --tx-out addr_test1qrf5lmxa4zqgquzgvfwt78cf4upy4drffj0ytzyd9gx7vpzuw64zlm7ykrpcsmf29t00vd96jpq2hywxf5t2yf84wd7sdwlrtt+1400000+"200 $RTOKEN_POLICY_ID_NAME" \
  \
  --tx-in $POOL_UTXO \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value $SCRIPT_DATA \
  --tx-in-redeemer-value 100 \
  --tx-out $SCRIPT_ADDR+$LOVELACE_END_VALUE+"$RTOKEN_END_VALUE $RTOKEN_POLICY_ID_NAME"+"1 $NFTPOOLTOKEN_POLICY_ID_NAME" \
  --tx-out-datum-hash $SCRIPT_DATUM_HASH \
  \
  "${SEND_SWAPTOKENS_TO_ISSUER[@]}" \
  --tx-in-collateral $MY_UTXO \
  --protocol-params-file $ROOT_DIR/protocol.json \
  --change-address $MY_ADDR \
  --out-file tx.build
set +x
echo "Done."

# Sign tx 
echo "Sign Tx ..."
## if SwapTokens are burning
# ${CARDANO_CLI_PATH} transaction sign \
# --signing-key-file $DIR/payment.skey \
# --signing-key-file $DIR_POLICY/policy.skey \
# --tx-body-file tx.build \
# --out-file tx.sign
## if SwapTokens are sending to tx issuer
${CARDANO_CLI_PATH} transaction sign \
--signing-key-file $DIR/payment.skey \
--signing-key-file $DIR_POLICY/policy.skey \
--tx-body-file tx.build \
--out-file tx.sign
echo "Done."

# Submit tx
echo "Submiting Tx ..."
${CARDANO_CLI_PATH} transaction submit $NETWORK --tx-file tx.sign