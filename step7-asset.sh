#!/bin/bash
# Step 7: issue IoVCredit (replaces ether), fund the RSU treasury, register vehicles
source /work/iov.sh

echo "----- Issuing IoVCredit -----"
RA issue $RA_ADDR '{"name":"IoVCredit","open":true}' 100000 1
echo "waiting for the next block..."
sleep 20

echo "----- Funding RSU1 reward treasury -----"
RA sendasset $RSU1_ADDR IoVCredit 1000

echo "----- Registering vehicles (initial TV = 2) -----"
i=1
for v in $V1 $V2 $V3 $V4 $V5; do
  RA publish vehicle_registry $v '{"json":{"tv":2,"status":"active","region":"A"}}'
  echo "V$i $v PSN-000$i" >> /work/ra-private-map.txt
  i=$((i+1))
done
echo "waiting for the next block..."
sleep 20

echo "----- Asset info -----"
RA listassets IoVCredit | jq '.[0] | {name, issueqty, units}'

echo "----- RSU1 treasury balance -----"
RSU1 getaddressbalances $RSU1_ADDR | jq -r '.[] | "\(.name)\t\(.qty)"'

echo "----- vehicle_registry (as seen by RSU2, proving replication) -----"
RSU2 liststreamitems vehicle_registry | jq -r '.[] | "\(.keys[0])\t\(.data.json | tojson)"'

echo "----- RA private pseudonym map (off-chain) -----"
cat /work/ra-private-map.txt
