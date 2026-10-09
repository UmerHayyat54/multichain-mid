#!/bin/bash
# Runs the whole implementation (Steps 2-14) in order inside a FRESH container.
# Takes about 20-25 minutes because each step waits for blocks (15 s block time).
# usage (inside the container, from /work):  bash run-all.sh            (all steps)
#                                            bash run-all.sh --no-bench (skip Step 14)
set -e
cd /work

if [ -d /root/.multichain/iovregionA ]; then
  echo "iovregionA already exists in this container."
  echo "Start a fresh container (see README) or, to restart the existing nodes, run: bash start-all.sh"
  exit 1
fi

# remove generated files from an earlier run
rm -f iov.sh start-all.sh ra-private-map.txt join-*.log

STEPS="setup-params.sh step3-ra.sh step4-join.sh step5-grant.sh step6-streams.sh step7-asset.sh \
step8-filter.sh step9-reports.sh step10-analyse.sh step11-hard.sh step12-rotation.sh step13-global.sh"
[ "$1" != "--no-bench" ] && STEPS="$STEPS step14-bench.sh"

for s in $STEPS; do
  echo
  echo "################################################################"
  echo "### $s"
  echo "################################################################"
  bash "$s" 2>&1 | tee -a run.log
done
echo
echo "Done. Full output saved in run.log"
