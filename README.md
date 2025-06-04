# UZH Cardano Network Bootstrap Node
[0. Configure Shelley genesis file](#0-configure-shelley-genesis-file) \
[1. Run a Bootstrap node](#1-run-bootstrap-nodes) \
[2. Run a relay node](#2-run-a-relay-note) \
[3. Run Cardano db sync](#3-run-cardano-db-sync) \
[4. Run Blockfrost](#4-run-blockfrost) \
[5. Run Nami wallet](#5-run-nami-wallet) 

## 0. Configure shelley genesis file
This step is not necessary because the /keys folder has all the necessary which are corresponded to the Shelley genesis file. If we want to change the keys, Shelley genesis must be changed manually.

These are the commands to generate them:
```bash
Generate Utxo-keys: 

cardano-cli address key-gen \  
--verification-key-file payment.vkey \  
--signing-key-file payment.skey  
 
cardano-cli stake-address key-gen \  
--verification-key-file stake.vkey \  
--signing-key-file stake.skey 
 
cardano-cli address build \  
--payment-verification-key-file payment.vkey \  
--stake-verification-key-file stake.vkey \  
--out-file payment.addr \  
--testnet-magic 2025 

This is the initial fund's address:
cardano-cli address info --address addr_test1qztc80na8320zymhjekl40yjsnxkcvhu58x59mc2fuwvgkls6c2fnu8cyfjfxljyvpwt5qamtyrzl69zyva308y0vntsfhv6r9 
```


```bash
Generate Pool-keys: 

# sometime the cold.*key are also named as node.*key, node.counter
cardano-cli node key-gen \  
--cold-verification-key-file cold.vkey \  
--cold-signing-key-file cold.skey \  
--operational-certificate-issue-counter cold.counter  

cardano-cli node key-gen-KES \  
--verification-key-file kes.vkey \  
--signing-key-file kes.skey  

cardano-cli node key-gen-VRF \  
--verification-key-file vrf.vkey \  
--signing-key-file vrf.skey  

chmod 400 vrf.skey 

# The title is the dictionary path, e.g., staking.pools = {staking:{pools:...}}
staking.pools:
cardano-cli stake-pool id --cold-verification-key-file cold.vkey --output-format hex

staking.stake:
cardano-cli stake-address key-hash --stake-verification-key-file stake.vkey

staking.vrf:
cardano-cli node key-hash-VRF --verification-key-file vrf.vkey

```


## 1. Run a Bootstrap node

### Prerequisites

First, let's git clone the repository in ~ folder:
```bash
cd ~
git clone https://github.com/Li-Guangyao/UZH-Cardano-Network-Bootstrap.git
```

For folder structure, we will use the guild operator scripts.

```bash
mkdir "$HOME/tmp"
cd "$HOME/tmp"
curl -sS -o guild-deploy.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/guild-deploy.sh
chmod 755 guild-deploy.sh
```

For cardano-node, we will use the latest pre-built binaries available which can be downloaded automatically in the ~/.local/bin directory after executing:

```bash
./guild-deploy.sh -s d

. "${HOME}/.bashrc"
```

### Update node producer pool name 
Before you go ahead with starting your node, update value for POOL_NAME in $CNODE_HOME/scripts/env.

```bash
vim $CNODE_HOME/scripts/env

# set this item:
POOL_NAME="pool1"
```

### Source the changes
```bash
. "${HOME}/.bashrc"
```

For latest guild operator commands and to build the binaries locally using cabal, refer the guild operator documenation.
(https://cardano-community.github.io/guild-operators/basics/)

       
### Configuring the deployment

All parameters are configured via environment variables (env.sh)
The POOL_NAME mentioned in the guild operator env file should match with the POOL_NAME mentioned for the private network so that the keys can be copied and the node can start as block producer.


```bash
cd ~/UZH-Cardano-Network-Bootstrap
source env.sh
```

#### Update the genesis files with a new start time:

```bash
cd ~/UZH-Cardano-Network-Bootstrap
./update-genesis-start-time.sh
```

Every execution of update-genesis-start-time.sh will generate a unique genesis file, because the parameter "systemStart" is the result of `date +${DELAY}`. If you've configured your enviroment with DELAY=5, you will have 5min to deploy the testnet. If no block producer is present at that point in time, the network (for that genesis hash) will be dead on arrival. 

This will also copy the config files and the keys to run the cardano node.

### Deploying private instance

1. Deploy as a systemd service
Execute the below command to deploy your node as a systemd service (from the respective scripts folder):

```bash
cd $CNODE_HOME/scripts
./cnode.sh -d
```

Before starting the node, it's better to check if the file ‘protocolMagicId’ exists:
```bash
test -f /opt/cardano/cnode/db/protocolMagicId && echo "protocolMagicId exist" || echo "protocolMagicId doesn't exist"
```
If exists, check its content to see if it's 2025. If not, change it to 2025.
```bash
cat /opt/cardano/cnode/db/protocolMagicId
```
If protocolMagicId doesn't exist, create one:
```bash
echo 2025 > /opt/cardano/cnode/db/protocolMagicId
```



2. Start the service

Run below commands to enable automatic start of service on startup and start it.

```bash
sudo systemctl start cnode.service
```

3. Check status and stop/start commands Replace status with stop/start/restart depending on what action to take.

```bash
sudo systemctl status cnode.service

journalctl -u cnode -f

$CNODE_HOME/scripts/gLiveView.sh
```


#### Important

In case you see the node exit unsuccessfully upon checking status, please verify you've followed the transition process correctly as documented below, and that you do not have another instance of node already running. It would help to check your system logs (/var/log/syslog for debian-based and /var/log/messages for Red Hat/CentOS/Fedora systems, you can also check journalctl -f -u <service> to examine startup attempt for services) for any errors while starting node.

### Generate Addresses and fund:

```bash
cd scripts
./step1-generate-utxo-keys-and-address.sh
```

Send funds to the address from the bootstrap node:
```bash
cd scripts
./faucet.sh <AMOUNT_IN_LOVELACE> <ADDRESS>
```

## 2. Run a Relay node

To run a relay node, the config file generated for the block producer node will be used. The topology file for the relay node has to be updated to connect to the block producer node.
For setup, 
1. start with same pre-requisites but do not set the pool name for this instance
2. Copy the genesis files from the block producer for relay node
3. Update topology file to be able to connect to the block producer node
4. Run relay node as systemd service and let it sync up.

### Running grafana on relay node for monitoring 
Once your Cardano pool is successfully set up, then comes the most beautiful part - setting up your Dashboard and Alerts!

    https://developers.cardano.org/docs/operate-a-stake-pool/grafana-dashboard-tutorial/

## 3. Run Cardano db sync
Here is a reference:
How to set up the postgres: https://cardano-community.github.io/guild-operators/Appendix/postgres/

How to set up the DB Sync: https://cardano-community.github.io/guild-operators/Build/dbsync/

Following is the practical procedure we set it:

### Prerequisites
Ensure the following tools and dependencies are installed:
- PostgreSQL
- Docker
- Cardano Node
- Git
---

### Configure dbsync.json
```bash
vim /opt/cardano/cnode/files/dbsync.json
```
Update:
```json
"RequiresNetworkMagic": "RequiresMagic",
"minSeverity": "Info",
```

### Update environment
```bash
vim /opt/cardano/cnode/scripts/env

Set:
CNODE_HOME="/opt/cardano/cnode"
```
### Restart cnode
```bash
sudo systemctl restart cnode
~/.local/bin/cardano-db-sync version
```

### Download submit-api-config.json
```bash
cd /opt/cardano/cnode/files
wget https://book.world.dev.cardano.org/environments/preview/submit-api-config.json
```

### Create pgpass file
```bash
vim $CNODE_HOME/priv/.pgpass

# write:
localhost:5432:cexplorer:postgres:postgres

# Save, quit and give permission:
chmod 600 /opt/cardano/cnode/priv/.pgpass
```

Node: Later I found that DBSync always fails due to the reason "cardano-db-sync: libpq: failed (could not translate host name "*" to address: Try again". It seems that the PGPASSFILE needs always to be accessible. So I use 2 methods:
1. write PGPASSFILE in the environment:
```bash
nano ~/.bashrc
# add:
export PGPASSFILE=/opt/cardano/cnode/priv/.pgpass
source ~/.bashrc
```

2. write PGPASSFILE in the cnode-dbsync environment:
```bash
sudo systemctl edit cnode-dbsync

# add the following
[Service]
Environment=PGPASSFILE=/opt/cardano/cnode/priv/.pgpass

# save, quit and execute
sudo systemctl daemon-reexec
sudo systemctl restart cnode-dbsync
```

### Clone db-sync Repository
```bash
cd ~/git
git clone https://github.com/intersectmbo/cardano-db-sync
cd cardano-db-sync
~/git/cardano-db-sync/scripts/postgresql-setup.sh --createdb
```

### Create Schema Symlink
```bash
ln -s ~/git/cardano-db-sync/schema $CNODE_HOME/guild-db/schema
```

### Start DB-Sync
```bash
export PGPASSFILE=$CNODE_HOME/priv/.pgpass
$CNODE_HOME/scripts/dbsync.sh -d
sudo systemctl enable cnode-dbsync
sudo systemctl start cnode-dbsync
sudo systemctl status cnode-dbsync

# check the status (just output the last 100 lines):
journalctl -u cnode-dbsync -n 100
```

### Verify DB Sync
```bash
psql cexplorer
SELECT count(*) FROM tx_in;
```


### Setting up db-sync as systemd service

The db-sync can be easily set using guild operator scripts
(https://cardano-community.github.io/guild-operators/Build/dbsync/)

USeful Queries - https://github.com/input-output-hk/cardano-db-sync/blob/master/doc/interesting-queries.md 


### Add a watchdog script to prevent dbsync fails
This step is optional. \
Full Script: ~/check_dbsync.sh
```bash
#!/bin/bash

SERVICE_NAME="cnode-dbsync.service"
SETUP_SCRIPT="$HOME/git/cardano-db-sync/scripts/postgresql-setup.sh"
LOG_FILE="$HOME/dbsync_watchdog.log"
DB_PASSWORD="postgres"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

run_setup_script() {
expect <<EOF
log_user 1
set timeout 30
spawn bash $SETUP_SCRIPT --createdb
expect {
    -re "(?i)password.*" {
        send "$DB_PASSWORD\r"
        exp_continue
    }
    eof
}
EOF
}

# Check if the service is active
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log "Service is active. No action needed."
else
    log "Service is inactive. Attempting recovery..."

    log "Running setup script (1st time)..."
    run_setup_script

    log "Running setup script (2nd time)..."
    run_setup_script

    log "Restarting $SERVICE_NAME..."
    sudo systemctl restart "$SERVICE_NAME"

    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log "Service restarted successfully."
    else
        log "Service failed to restart."
    fi
fi

```

Then:
```bash
chmod +x ~/check_dbsync.sh

crontab -e
# add this. To check the service every 5 minites 
*/5 * * * * /home/YOUR_USERNAME/check_dbsync.sh
```


## 4. Run Blockfrost
### Clone Blockfrost Repository
```bash
cd ~/git
git clone https://github.com/blockfrost/blockfrost-backend-ryo
cd blockfrost-backend-ryo
```

### Configure development.yaml
```bash
cd ~/git/blockfrost-backend-ryo/config
vim ./development.yaml
```
Set the following:
```yaml
server:
  listenAddress: "0.0.0.0"
  port: 3000
  debug: true
dbSync:
  host: "localhost"
  port: 5432
  user: "postgres"
  database: "cexplorer"
  password: "postgres"
  maxConnections: 10
network: "preview"
```

### Run Blockfrost in Docker
```bash
sudo apt install docker.io
sudo docker run --rm \
  --name blockfrost-ryo \
  --network host \
  -p 3000:3000 \
  -e BLOCKFROST_CONFIG_SERVER_LISTEN_ADDRESS=0.0.0.0 \
  -e BLOCKFROST_CONFIG_SERVER_PORT=3000 \
  -e BLOCKFROST_CONFIG_SERVER_DEBUG=True \
  -e BLOCKFROST_CONFIG_SERVER_PROMETHEUS_METRICS=False \
  -e BLOCKFROST_CONFIG_DBSYNC_HOST=localhost \
  -e BLOCKFROST_CONFIG_DBSYNC_PORT=5432 \
  -e BLOCKFROST_CONFIG_DBSYNC_USER=postgres \
  -e BLOCKFROST_CONFIG_DBSYNC_DATABASE=cexplorer \
  -e BLOCKFROST_CONFIG_DBSYNC_MAX_CONN=10 \
  -e BLOCKFROST_CONFIG_NETWORK=preview \
  -e BLOCKFROST_CONFIG_DBSYNC_PASSWORD=postgres \
  -e BLOCKFROST_CONFIG_TOKEN_REGISTRY_URL="https://metadata.world.dev.cardano.org" \
  -v $PWD/config:/app/config \
  blockfrost/backend-ryo:latest
```

### Configure Submit API
```bash
vim /opt/cardano/cnode/scripts/submitapi.sh
```
Set:
```bash
HOSTADDR=0.0.0.0
HOSTPORT=8090

# scroll down to the bottom:
"${SUBMITAPIBIN}" --config "/opt/cardano/cnode/files/submit-api-config.json" \\
  --testnet-magic 2025 --socket-path "${CARDANO_NODE_SOCKET_PATH}" \\
  --listen-address ${HOSTADDR} --port ${HOSTPORT}
```

### Start Submit API
```bash
/opt/cardano/cnode/scripts/submitapi.sh -d
sudo systemctl enable cnode-submit-api
sudo systemctl start cnode-submit-api
sudo systemctl status cnode-submit-api
```

### Health Check
```bash
curl http://localhost:3000/health
curl http://<server_ip>:3000/health
  {"is_healthy":true}
```

### Run Nginx
If you want to submit a transaction using Python or other high-level langugae with Cardano's official package, it may send requests to port 80 defaultly. However, when starting up blockfrost, we set the port as 3000, so the most simple way is to run a Nginx server to forward all the requests from port 80 to 3000.

```bash
sudo apt update
sudo apt install nginx -y

# Configure the firewall(ubuntu)
sudo ufw allow 'Nginx Full'

sudo nano /etc/nginx/sites-available/default

# Set it like this
server {
    listen 80;
    server_name _;

    location / {
    proxy_pass                            http://localhost:3000/;
  
    chunked_transfer_encoding             off;
    proxy_buffering                       off;
    proxy_http_version                    1.1;
    proxy_redirect                        off;
    proxy_set_header Host                 $host;
    proxy_set_header X-Forwarded-For      $remote_addr;
    proxy_set_header X-Forwarded-Host     $http_host;
    proxy_set_header X-Forwarded-Proto    $scheme;
    proxy_set_header X-Forwarded-Protocol $scheme;
    proxy_set_header X-Real-IP            $remote_addr;

    # Sets the maximum allowed size of the client request body.
    client_max_body_size               0;
  }
  
  location /v0/ {
    proxy_pass                            http://localhost:3000/;
    rewrite ^/v0/(.*)$ /$1 break;
  
    chunked_transfer_encoding             off;
    proxy_buffering                       off;
    proxy_http_version                    1.1;
    proxy_redirect                        off;
    proxy_set_header Host                 $host;
    proxy_set_header X-Forwarded-For      $remote_addr;
    proxy_set_header X-Forwarded-Host     $http_host;
    proxy_set_header X-Forwarded-Proto    $scheme;
    proxy_set_header X-Forwarded-Protocol $scheme;
    proxy_set_header X-Real-IP            $remote_addr;
  
    # Sets the maximum allowed size of the client request body.
    client_max_body_size               0;

}

sudo nginx -t  # check if the configure is right
sudo systemctl restart nginx

sudo lsof -i :80
```



## 5. Run Nami wallet
Clone the repository
```bash
git clone https://github.com/Godspeed-exe/nami.git
```
3 places can be modified:
```bash
/src/ui/app/pages/setting.jsx  -> line 503
/src/api/extension/index.js -> line 1152
/src/config/config.js -> line 74
```

Then:
```bash
npm i
npm run build
```