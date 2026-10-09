#!/bin/bash
# Step 14: benchmark like the paper - N reports sent asynchronously, time until all are confirmed
# usage: bash step14-bench.sh [LABEL]   (default 4miners)
source /work/iov.sh
LABEL=${1:-4miners}
OUT=/work/bench-$LABEL.csv
echo "N,submit_s,total_s,tps,failed" > $OUT

echo "===== Benchmark: $LABEL  (block time $(RA getblockchainparams | jq '."target-block-time"') s) ====="
printf "%-6s %-10s %-10s %-8s %s\n" N submit_s total_s tx/s failed
for N in 1 100 500 750 1000; do
  fail=0
  t1=$(date +%s.%N)
  for i in $(seq 1 $N); do
    VEH publishfrom $V2 misbehaviour_reports "[\"B-$LABEL-$N-$i\",\"$V4\"]" \
      "{\"json\":{\"session\":\"B-$LABEL-$N-$i\",\"suspect\":\"$V4\",\"event\":\"bench\",\"speed_kmh\":40,\"lat\":10.2,\"lon\":20.3}}" \
      > /dev/null 2>/tmp/bench-err.txt || fail=$((fail+1))
  done
  t_sub=$(date +%s.%N)
  while [ "$(VEH getmempoolinfo | jq .size)" -gt 0 ]; do sleep 0.5; done
  t2=$(date +%s.%N)
  sub=$(echo "$t_sub - $t1" | bc); tot=$(echo "$t2 - $t1" | bc)
  tps=$(echo "scale=2; ($N - $fail) / $tot" | bc)
  printf "%-6s %-10.2f %-10.2f %-8s %s\n" $N $sub $tot $tps $fail
  echo "$N,$sub,$tot,$tps,$fail" >> $OUT
  [ "$fail" -gt 0 ] && { echo "first error:"; cat /tmp/bench-err.txt; }
done
echo "saved to $OUT"
