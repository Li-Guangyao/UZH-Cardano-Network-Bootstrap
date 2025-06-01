#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./copy_pool_keys.sh <pool_name>"
    return 1
fi

NETWORK_MAGIC="--testnet-magic 2025"

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

UTXO_KEYS_PATH=~/keys/utxo-keys
POOL_KEYS_PATH=~/keys/pool-keys

# Check if the directories exist
if [ ! -d "$UTXO_KEYS_PATH" ]; then
    echo "Error: UTXO keys directory does not exist at $UTXO_KEYS_PATH"
    exit 1
fi

if [ ! -d "$POOL_KEYS_PATH" ]; then
    echo "Error: Pool keys directory does not exist at $POOL_KEYS_PATH"
    exit 1
fi

# Check if the required files exist
if [ ! -f ~/keys/node-keys/kes.skey ]; then
    echo "Error: File kes.skey does not exist in ~/keys/node-keys. Please create it first."
    exit 1
fi

if [ ! -f ~/keys/node-keys/vrf.skey ]; then
    echo "Error: File vrf.skey does not exist in ~/keys/node-keys. Please create it first."
    exit 1
fi

if [ ! -f ~/keys/node-keys/opcert.cert ]; then
    echo "Error: File opcert.cert does not exist in ~/keys/node-keys. Please create it first."
    exit 1
fi

# Copy the keys
cp ~/keys/node-keys/kes.skey $CNODE_HOME/priv/pool/$POOL_NAME/hot.skey
cp ~/keys/node-keys/vrf.skey $CNODE_HOME/priv/pool/$POOL_NAME/vrf.skey
cp ~/keys/node-keys/opcert.cert $CNODE_HOME/priv/pool/$POOL_NAME/op.cert

sudo chmod o-rwx $CNODE_HOME/priv/pool/$POOL_NAME/vrf.skey
sudo chmod g-rwx $CNODE_HOME/priv/pool/$POOL_NAME/vrf.skey

# cp -r keys/utxo-keys/* $CNODE_HOME/initial-keys