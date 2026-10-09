#!/bin/bash
# Step 6: vehicle addresses V1-V5, streams (replace Solidity registers), write permissions
source /work/iov.sh

echo "----- Creating vehicle addresses V1-V5 -----"
for i in 1 2 3 4 5; do echo "V$i=$(VEH getnewaddress)" >> /work/iov.sh; done
source /work/iov.sh
RA grant $V1,$V2,$V3,$V4,$V5 send,receive

echo "----- Creating streams -----"
for s in vehicle_registry misbehaviour_reports trust_updates revocation_list region_events; do
  RA create stream $s false
done
echo "waiting for the next block..."
sleep 20

echo "----- Stream write permissions -----"
RA grant $V1,$V2,$V3,$V4,$V5 misbehaviour_reports.write
RA grant $V1,$V2,$V3,$V4,$V5 region_events.write
RA grant $RSU1_ADDR,$RSU2_ADDR,$RSU3_ADDR trust_updates.write
RA grant $RSU1_ADDR,$RSU2_ADDR,$RSU3_ADDR revocation_list.write

echo "----- Subscribing every node to every stream -----"
for n in RA RSU1 RSU2 RSU3 VEH; do
  for s in vehicle_registry misbehaviour_reports trust_updates revocation_list region_events; do
    $n subscribe $s
  done
  echo "$n subscribed"
done
sleep 20

echo "----- Vehicle addresses -----"
for v in V1 V2 V3 V4 V5; do echo "$v = ${!v}"; done

echo "----- Streams -----"
RA liststreams | jq -r '.[] | "\(.name)\trestrict-write=\(.restrict.write)\tconfirmed=\(.confirmed)"'

echo "----- Who can write to misbehaviour_reports (expect V1-V5 + RA) -----"
RA listpermissions misbehaviour_reports.write | jq -r '.[].address'
echo "----- Who can write to trust_updates (expect RSU1-3 + RA) -----"
RA listpermissions trust_updates.write | jq -r '.[].address'
