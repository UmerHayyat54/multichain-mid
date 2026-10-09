#!/bin/bash
# Step 8: compile, create and approve the smart filter on misbehaviour_reports
source /work/iov.sh

echo "----- Compile check -----"
RA teststreamfilter '{}' "$(cat /work/reportFilter.js)"

echo "----- Creating filter -----"
RA create streamfilter reportFilter '{}' "$(cat /work/reportFilter.js)"
echo "waiting for the next block..."
sleep 20

echo "----- Approving filter for misbehaviour_reports -----"
RA approvefrom $RA_ADDR reportFilter '{"for":"misbehaviour_reports","approve":true}'
echo "waiting for the next block..."
sleep 20

echo "----- Stream filters on the chain -----"
RA liststreamfilters
