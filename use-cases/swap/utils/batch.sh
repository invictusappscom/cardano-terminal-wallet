echo "Building Tx ..."
set -xe

POOL_UTXO=3a29543053a95d39d6b5df5bcae7371fd64e9e3fe26b64e17e67d482f027f79c#1
# SwapTokens taken from Swap Orders which goes to the script
SWAP_TOKENS_END_VALUE=$((100 + 60))
# Lovalace taken from Swap Orders which goes to the script, also fee needs to be included (after first start it will be error missing ada eg -202067)
LOVELACE_END_VALUE=$((14000000 - 10000000 + 3000000 - 1400000 - 202067))
RTOKEN_END_VALUE=$((288 + 200 - 60))

# Dodati zamenske vredonosti valute na tx-out i takodje LP utxo na ulazu, za collateral staviti isto utxo novcanika koji izvrsava
${CARDANO_CLI_PATH} transaction build \
  --alonzo-era \
  $NETWORK \
  \
  --tx-in 941a7f0159053338f4ee97c19b2d3fcf802f137a4d6bdac301871a37da72e97a#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1qqp6z9xneafqp0ndrxgyjd3qecs4tf6ktqhvj2hyc5efg2gzq5lqcm","6rfuv6yp0mtsgc2qxvwlwr938qk2nue0rqg6rqxewe52"]' \
  --tx-in-redeemer-value 1 \
  --tx-out addr_test1qqp6z9xneafqp0ndrxgyjd3qecs4tf6ktqhvj2hyc5efg2gzq5lqcm6rfuv6yp0mtsgc2qxvwlwr938qk2nue0rqg6rqxewe52+11900000 \
  \
  --tx-in c5692c4242bfd6a52b1eb33ada17fe65a7291644baeec08644b3df8bfdb0267a#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1qz270xngvhp50nvc5cxktsuh6tf7s3sanh5gyqr4dphx6qzdvmtrj9","qmssswlxaty64q9xukz3z3xecqch6hvfcn8tqq0g3wej"]' \
  --tx-in-redeemer-value 100 \
  --tx-out addr_test1qz270xngvhp50nvc5cxktsuh6tf7s3sanh5gyqr4dphx6qzdvmtrj9qmssswlxaty64q9xukz3z3xecqch6hvfcn8tqq0g3wej+1400000+"60 29856eae5151337853ffbd8fd80df78dab8c7f09c37c95799328abb8.REVU" \
  \
  --tx-in $POOL_UTXO \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1wpnlxv2xv9a9ucvnvzqakwepzl9ltx7jzgm53av2e9ncv4sysemm8",""]' \
  --tx-in-redeemer-value 100 \
  --tx-out $SCRIPT_ADDR+$LOVELACE_END_VALUE+"$RTOKEN_END_VALUE 29856eae5151337853ffbd8fd80df78dab8c7f09c37c95799328abb8.REVU"+"$SWAP_TOKENS_END_VALUE d9a1156d008866951090923bb1d39587aaebb342c50e5fb848f5d84f.SwapToken" \
  --tx-out-datum-hash $DATUM_HASH \
  \
  --tx-in-collateral $MY_UTXO \
  --protocol-params-file $ROOT_DIR/protocol.json \
  --change-address $MY_ADDR \
  --out-file tx.build
set +x
echo "Done."

# Sign tx
echo "Sign Tx ..."
${CARDANO_CLI_PATH} transaction sign \
--signing-key-file $DIR/payment.skey \
--tx-body-file tx.build \
--out-file tx.sign
echo "Done."

# Submit tx
echo "Submiting Tx ..."
${CARDANO_CLI_PATH} transaction submit $NETWORK --tx-file tx.sign