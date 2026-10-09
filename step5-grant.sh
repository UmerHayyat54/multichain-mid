#!/bin/bash
# Step 5: RA grants permissions, then RSU and vehicle nodes start as daemons
source /work/iov.sh

echo "----- Granting permissions -----"
RA grant $RSU1_ADDR,$RSU2_ADDR,$RSU3_ADDR connect,send,receive,mine
RA grant $RSU1_ADDR,$RSU2_ADDR,$RSU3_ADDR admin
RA grant $VEH_ADDR connect,send,receive

cat > /work/start-all.sh <<'EOF'
#!/bin/bash
# start every node of iovregionA (run after a container restart)
multichaind iovregionA -daemon
sleep 3
multichaind iovregionA -datadir=/root/.mc-rsu1 -port=7461 -rpcport=7460 -daemon
multichaind iovregionA -datadir=/root/.mc-rsu2 -port=7463 -rpcport=7462 -daemon
multichaind iovregionA -datadir=/root/.mc-rsu3 -port=7465 -rpcport=7464 -daemon
multichaind iovregionA -datadir=/root/.mc-veh  -port=7467 -rpcport=7466 -daemon
EOF

echo "----- Starting RSU and vehicle nodes -----"
multichaind iovregionA -datadir=/root/.mc-rsu1 -port=7461 -rpcport=7460 -daemon
multichaind iovregionA -datadir=/root/.mc-rsu2 -port=7463 -rpcport=7462 -daemon
multichaind iovregionA -datadir=/root/.mc-rsu3 -port=7465 -rpcport=7464 -daemon
multichaind iovregionA -datadir=/root/.mc-veh  -port=7467 -rpcport=7466 -daemon
sleep 15

echo "----- Peers connected to RA (expect 4) -----"
RA getpeerinfo | jq length

echo "----- Permissions: mine and admin -----"
RA listpermissions mine,admin | jq -r '.[] | "\(.type)\t\(.address)"'

echo "----- Blocks seen by each node (should match) -----"
echo "RA   $(RA getinfo | jq .blocks)"
echo "RSU1 $(RSU1 getinfo | jq .blocks)"
echo "RSU2 $(RSU2 getinfo | jq .blocks)"
echo "RSU3 $(RSU3 getinfo | jq .blocks)"
echo "VEH  $(VEH getinfo | jq .blocks)"
