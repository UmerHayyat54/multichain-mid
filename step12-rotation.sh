#!/bin/bash
# Step 12: show that mining-diversity is enforced after the setup phase (block > setup-first-blocks)
source /work/iov.sh
name() { grep -E "^(V[1-5]|RA_ADDR|RSU[1-3]_ADDR)=$1$" /work/iov.sh | cut -d= -f1; }

echo "===== Consensus parameters ====="
RA getblockchainparams | jq '{"setup-first-blocks", "mining-diversity", "target-block-time", "anyone-can-mine"}'
START=$(( $(RA getblockchainparams | jq '."setup-first-blocks"') + 1 ))
echo "current block: $(RA getblockcount)   rotation is enforced from block $START"

echo "===== Generating traffic for ~4 minutes (heartbeat every 15 s) ====="
for i in $(seq 1 16); do
  VEH publishfrom $V1 region_events $V1 "{\"json\":{\"event\":\"heartbeat\",\"n\":$i}}" > /dev/null
  echo -n "."
  sleep 15
done
echo

END=$(RA getblockcount)
echo "===== Miners of blocks $START-$END (after setup phase) ====="
RA listblocks "$START-$END" | jq -r '.[] | "\(.height) \(.miner)"' | \
  while read h m; do echo "block $h  mined by $(name $m)"; done
