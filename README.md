## Cardano Terminal Wallet

### Requirements
```bash
cp .env.example .env
```

You need full cardano-node installed or it is easier [Daedalus Wallet Testnet](https://testnets.cardano.org/en/testnets/cardano/get-started/wallet/) which is shipped with cardano-node. 

Make sure that `CARDANO_NODE_SOCKET_PATH` environment variable is properly set in .env. If you are using Daedalus testnet you can check with:
```bash
echo $(ps ax | grep -v grep | grep cardano-wallet | grep testnet | sed -E 's/(.*)node-socket //')
```
You will need also cardano-cli which can be downloaded [Here](https://github.com/input-output-hk/cardano-wallet/releases/tag/v2021-09-09). Put it in your PATH or set in .env variable `CARDANO_CLI_PATH` to target your cardano-cli file.

### Features
1. Create Wallet with script `./create-wallet` and follow instructions
[![asciicast](https://asciinema.org/a/v9WMidewy5QIAizudEZF0YlDO.svg)](https://asciinema.org/a/v9WMidewy5QIAizudEZF0YlDO)
2. Recreate wallet with script `./recreate-wallet.sh` you will need to populate file `phrase-testnet.prv` with seed phrase. Please note that it will be recovered just one address path `1852H/1815H/0H/0/0` you can change this params inside script. 
3. Get Utxos from address with script `./balance.sh`
4. Send ADA to another wallet with script `./send-ada.sh`
[![asciicast](https://asciinema.org/a/BOJ5g9n0fZiQHT8YvY8cDVOGD.svg)](https://asciinema.org/a/BOJ5g9n0fZiQHT8YvY8cDVOGD)
5. Mint native tokens or NFT with scripts `./mint` and `./mint-nft`
[![asciicast](https://asciinema.org/a/ulSaJP8HXoXC6Kd5X3dCvq2EA.svg)](https://asciinema.org/a/ulSaJP8HXoXC6Kd5X3dCvq2EA)
6. Send native tokens or NFTs with script `./send-token`
[![asciicast](https://asciinema.org/a/bfLwieUvClqKd8RJ8s7wLGAlD.svg)](https://asciinema.org/a/bfLwieUvClqKd8RJ8s7wLGAlD)
7. Mint NFT with plutus using script `./mint-plutus-nft`. Script must be generated with https://github.com/jfischoff/plutus-nft and copied to `plutus/nft-mint-policy.plutus`