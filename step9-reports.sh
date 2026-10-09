#!/bin/bash
# Step 9: a session where V1-V4 report V5, plus negative tests for the smart filter
# usage: bash step9-reports.sh [SESSION]   (default S-101)
source /work/iov.sh
SESSION=${1:-S-101}
NOW=$(date +%s)

rep() {   # rep <reporter> <suspect> <speed_kmh> [lat]
  VEH publishfrom $1 misbehaviour_reports "[\"$SESSION\",\"$2\"]" \
    "{\"json\":{\"session\":\"$SESSION\",\"suspect\":\"$2\",\"event\":\"fake_road_clear\",\"speed_kmh\":$3,\"lat\":${4:-10.2},\"lon\":20.3,\"ts\":$NOW}}" 2>&1
}
name() { grep -E "^(V[1-5]|RA_ADDR|RSU[1-3]_ADDR)=$1$" /work/iov.sh | cut -d= -f1; }

echo "===== Session $SESSION: valid reports against V5 ====="
echo "V1 (alarmer): $(rep $V1 $V5 42)"
echo "V2:           $(rep $V2 $V5 38)"
echo "V3:           $(rep $V3 $V5 51)"
echo "V4:           $(rep $V4 $V5 47)"

if [ "$SESSION" = "S-101" ]; then
  echo
  echo "===== Negative tests (each must be REJECTED by reportFilter) ====="
  echo "[1] V5 reports itself:"
  rep $V5 $V5 40
  echo
  echo "[2] V2 claims 900 km/h:"
  rep $V2 $V5 900
  echo
  echo "[3] V3 position outside Region A (lat 50):"
  rep $V3 $V5 45 50.0
  echo
fi

echo "waiting for the next block..."
sleep 20

echo "===== Accepted reports in $SESSION (read from RSU1) ====="
RSU1 liststreamkeyitems misbehaviour_reports $SESSION | \
  jq -r '.[] | "\(.publishers[0]) \(.keys[1]) \(.data.json.speed_kmh) \(.confirmations)"' | \
  while read pub sus spd conf; do
    echo "$(name $pub) reported $(name $sus)  speed=${spd}km/h  confirmations=$conf"
  done
