echo "Building Tx ..."
set -xe

POOL_UTXO=f79be8ca385719d6fc5e73390b5256a24c1162bcbb86f88953d321c3c5818bc2#2
# SwapTokens taken from Swap Orders which goes to the script or it can be burned
SWAP_TOKENS_END_VALUE=$((20000000 + 200))
# Lovalace taken from Swap Orders which goes to the script, also fee needs to be included (after first start it will be error missing ada eg -202067)
ADA_IN=$((10000000 + 1900000 + 40287409))
# 204311 needs 205719
ADA_OUT=$((1400000 + 20000000 + 205719 + 3036))
LOVELACE_END_VALUE=$(($ADA_IN - $ADA_OUT))

RTOKEN_IN=$((400 + 400))
RTOKEN_OUT=$((200))
RTOKEN_END_VALUE=$(($RTOKEN_IN - $RTOKEN_OUT))

OVERRIDE_WITNESS="--witness-override 2"
BURN_SWAP_TOKENS=($OVERRIDE_WITNESS --mint "-$SWAP_TOKENS_END_VALUE $SWAPTOKEN_POLICY_ID_NAME" --mint-script-file $POLICY_SCRIPT)
# or
SEND_SWAPTOKENS_TO_ISSUER=(--tx-out $MY_ADDR+14000000+"$SWAP_TOKENS_END_VALUE $SWAPTOKEN_POLICY_ID_NAME")

# Build Tx - in tx-out for script address needs to be send all ada just to meke sure to not go to change address since change address is address of wallet of tx issuer
${CARDANO_CLI_PATH} transaction build \
  --alonzo-era \
  $NETWORK \
  \
  --tx-in 7e52451a90f9d51a1902ed7e81d81ab7786839bb930485dbfd3433e598d11f63#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1qp2e46x44jcrlylfxfgspkp2r464xeqr6tfl9j3u0cuw2pyl9gmg57","pnyzqk3wv0d02nn45qrw65gmxd7gytwmrpdhjqf4yeyl"]' \
  --tx-in-redeemer-value 1 \
  --tx-out addr_test1qp2e46x44jcrlylfxfgspkp2r464xeqr6tfl9j3u0cuw2pyl9gmg57pnyzqk3wv0d02nn45qrw65gmxd7gytwmrpdhjqf4yeyl+1400000+"200 $RTOKEN_POLICY_ID_NAME" \
  \
  --tx-in bcde7275eaf2028be8c660fcee2a474e32057f5d81821b9f4d24e65380870c63#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1qz270xngvhp50nvc5cxktsuh6tf7s3sanh5gyqr4dphx6qzdvmtrj9","qmssswlxaty64q9xukz3z3xecqch6hvfcn8tqq0g3wej"]' \
  --tx-in-redeemer-value 100 \
  --tx-out addr_test1qz270xngvhp50nvc5cxktsuh6tf7s3sanh5gyqr4dphx6qzdvmtrj9qmssswlxaty64q9xukz3z3xecqch6hvfcn8tqq0g3wej+20000000 \
  \
  --tx-in $POOL_UTXO \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value $SCRIPT_DATA \
  --tx-in-redeemer-value 100 \
  --tx-out $SCRIPT_ADDR+$LOVELACE_END_VALUE+"$RTOKEN_END_VALUE $RTOKEN_POLICY_ID_NAME"+"1 $NFTPOOLTOKEN_POLICY_ID_NAME" \
  --tx-out-datum-hash $SCRIPT_DATUM_HASH \
  \
  "${BURN_SWAP_TOKENS[@]}" \
  --tx-in-collateral $MY_UTXO \
  --protocol-params-file $ROOT_DIR/protocol.json \
  --change-address $MY_ADDR \
  --out-file tx.build
set +x
echo "Done."

# Sign tx 
echo "Sign Tx ..."
## if SwapTokens are burning
${CARDANO_CLI_PATH} transaction sign \
--signing-key-file $DIR/payment.skey \
--signing-key-file $DIR_POLICY/policy.skey \
--tx-body-file tx.build \
--out-file tx.sign
## if SwapTokens are sending to tx issuer
# ${CARDANO_CLI_PATH} transaction sign \
# --signing-key-file $DIR/payment.skey \
# --tx-body-file tx.build \
# --out-file tx.sign
echo "Done."

# Submit tx
echo "Submiting Tx ..."
${CARDANO_CLI_PATH} transaction submit $NETWORK --tx-file tx.sign