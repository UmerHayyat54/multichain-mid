#!/bin/bash
# Step 3: start the RA (genesis) node and create helper functions

multichaind iovregionA -daemon
sleep 5

cat > /work/iov.sh <<'EOF'
CHAIN=iovregionA
RA()   { multichain-cli -requestout=null $CHAIN "$@"; }
RSU1() { multichain-cli -requestout=null -datadir=/root/.mc-rsu1 -rpcport=7460 $CHAIN "$@"; }
RSU2() { multichain-cli -requestout=null -datadir=/root/.mc-rsu2 -rpcport=7462 $CHAIN "$@"; }
RSU3() { multichain-cli -requestout=null -datadir=/root/.mc-rsu3 -rpcport=7464 $CHAIN "$@"; }
VEH()  { multichain-cli -requestout=null -datadir=/root/.mc-veh  -rpcport=7466 $CHAIN "$@"; }
EOF

source /work/iov.sh
echo "RA_ADDR=$(RA getaddresses | jq -r '.[0]')" >> /work/iov.sh

echo "----- RA node info -----"
RA getinfo | jq '{chainname, description, protocol, port, blocks, connections}'
echo "----- RA address -----"
tail -1 /work/iov.sh
