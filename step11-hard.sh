#!/bin/bash
# Step 11: two more guilty sessions drive V5 below TV 0 (hard revocation), then proofs
source /work/iov.sh
name() { grep -E "^(V[1-5]|RA_ADDR|RSU[1-3]_ADDR)=$1$" /work/iov.sh | cut -d= -f1; }

for S in S-102 S-103; do
  echo "################ $S ################"
  bash /work/step9-reports.sh $S | grep -E "=====|reported"
  bash /work/step10-analyse.sh $S | grep -E "VERDICT|TV:|REVOCATION"
done

echo
echo "===== revocation_list ====="
RA liststreamitems revocation_list | jq -r '.[] | "\(.keys[0]) \(.data.json | tojson)"' | \
  while read a d; do echo "$(name $a)  $d"; done

echo "===== V5 permissions now (expect none) ====="
RA listpermissions send,receive $V5 | jq length

echo "===== A new report against revoked V5 (must be REJECTED by filter) ====="
VEH publishfrom $V1 misbehaviour_reports "[\"S-104\",\"$V5\"]" \
  "{\"json\":{\"session\":\"S-104\",\"suspect\":\"$V5\",\"event\":\"fake_road_clear\",\"speed_kmh\":40,\"lat\":10.2,\"lon\":20.3}}" 2>&1

echo "===== Final Trust Values and balances ====="
for v in V1 V2 V3 V4 V5; do
  a=${!v}
  t=$(RSU3 liststreamkeyitems trust_updates $a false 1 | jq -r '.[0].data.json.tv // "2"')
  b=$(VEH getaddressbalances $a | jq -r '[.[] | select(.name=="IoVCredit") | .qty] | add // 0')
  echo "$v  TV=$t  IoVCredit=$b"
done
echo "RSU1 treasury: $(RSU1 getaddressbalances $RSU1_ADDR | jq -r '.[] | select(.name=="IoVCredit") | .qty')"

echo "===== Miner rotation: last 12 blocks (no PoW, round-robin) ====="
RA listblocks "-12" | jq -r '.[] | "\(.height) \(.miner)"' | \
  while read h m; do echo "block $h  mined by $(name $m)"; done
