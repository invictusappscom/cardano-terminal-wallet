echo "Building Tx ..."
set -xe

# Dodati zamenske vredonosti valute na tx-out i takodje LP utxo n aulazu, za collateral staviti isto utxo novcanika koji izvrsava
${CARDANO_CLI_PATH} transaction build \
  --alonzo-era \
  $NETWORK \
  --tx-in 1f229b50cbd6340a3dec937929ea6c2332c8e632e56ea1b131b6a3c19a7d9b84#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1qqp6z9xneafqp0ndrxgyjd3qecs4tf6ktqhvj2hyc5efg2gzq5lqcm","6rfuv6yp0mtsgc2qxvwlwr938qk2nue0rqg6rqxewe52"]' \
  --tx-in-redeemer-value 1 \
  --tx-out addr_test1qqp6z9xneafqp0ndrxgyjd3qecs4tf6ktqhvj2hyc5efg2gzq5lqcm6rfuv6yp0mtsgc2qxvwlwr938qk2nue0rqg6rqxewe52+2000345+"100 d9a1156d008866951090923bb1d39587aaebb342c50e5fb848f5d84f.SwapToken" \
  \
  --tx-in fe809da736d315b8b3c99d39e3c74a0e053d8899943c92915cfe324db7a41472#1 \
  --tx-in-script-file $SCRIPT \
  --tx-in-datum-value '["addr_test1qqvxdvjcrwzqskge258qwax59nmuvt0veflk8pn4mmx603zv5t38e7","9gj3lgmvfdm8ntr2yau5khprzyyhzvn3lx04ssxrx6mt"]' \
  --tx-in-redeemer-value 100 \
  --tx-out addr_test1qqvxdvjcrwzqskge258qwax59nmuvt0veflk8pn4mmx603zv5t38e79gj3lgmvfdm8ntr2yau5khprzyyhzvn3lx04ssxrx6mt+2000123+"205 d9a1156d008866951090923bb1d39587aaebb342c50e5fb848f5d84f.SwapToken"
  \
  --tx-in-collateral $MY_UTXO \
  --protocol-params-file protocol.json \
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