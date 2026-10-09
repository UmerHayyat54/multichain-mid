#!/bin/bash
# Step 4: join RSU1-3 and the vehicle node to iovregionA (they stop until RA grants permission)

mkdir -p /root/.mc-rsu1 /root/.mc-rsu2 /root/.mc-rsu3 /root/.mc-veh

join() {
  multichaind iovregionA@127.0.0.1:7451 -datadir=/root/.mc-$1 -port=$2 -rpcport=$3 2>&1 \
    | tee /work/join-$1.log | grep -oE 'grant [[:alnum:]]+' | head -1 | awk '{print $2}'
}

RSU1=$(join rsu1 7461 7460)
RSU2=$(join rsu2 7463 7462)
RSU3=$(join rsu3 7465 7464)
VEHA=$(join veh 7467 7466)

echo "----- New node addresses -----"
echo "RSU1_ADDR=$RSU1"
echo "RSU2_ADDR=$RSU2"
echo "RSU3_ADDR=$RSU3"
echo "VEH_ADDR=$VEHA"

if [ -z "$RSU1" ] || [ -z "$RSU2" ] || [ -z "$RSU3" ] || [ -z "$VEHA" ]; then
  echo "ERROR: an address is empty - check the join-*.log files"
  exit 1
fi

echo "RSU1_ADDR=$RSU1" >> /work/iov.sh
echo "RSU2_ADDR=$RSU2" >> /work/iov.sh
echo "RSU3_ADDR=$RSU3" >> /work/iov.sh
echo "VEH_ADDR=$VEHA"  >> /work/iov.sh
echo "Saved to iov.sh"
