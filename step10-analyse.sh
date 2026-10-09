#!/bin/bash
# Step 10: RSU1 runs analyseReports (majority rule), punishes the suspect, rewards honest reporters
# usage: bash step10-analyse.sh [SESSION]   (default S-101, suspect V5)
source /work/iov.sh
SESSION=${1:-S-101}
SUSPECT=$V5
BLOCK_FOR=6     # soft revocation length in blocks (~1.5 min at 15 s/block)

name() { grep -E "^(V[1-5]|RA_ADDR|RSU[1-3]_ADDR)=$1$" /work/iov.sh | cut -d= -f1; }
tv_of() {
  t=$(RSU1 liststreamkeyitems trust_updates $1 false 1 | jq -r '.[0].data.json.tv // empty')
  [ -z "$t" ] && t=$(RSU1 liststreamkeyitems vehicle_registry $1 false 1 | jq -r '.[0].data.json.tv')
  echo $t
}

done_before=$(RSU1 liststreamkeyitems trust_updates $SUSPECT false 1000 | \
  jq --arg s "$SESSION" '[.[] | select(.data.json.session==$s and .data.json.verdict=="misbehaving")] | length')
if [ "$done_before" -gt 0 ]; then echo "Session $SESSION already analysed - skipping"; exit 0; fi

echo "===== analyseReports for $SESSION ====="
all=$(RSU1 liststreamkeyitems misbehaviour_reports $SESSION false 1000 | jq '[.[].publishers[0]] | unique | length')
against=$(RSU1 liststreamqueryitems misbehaviour_reports "{\"keys\":[\"$SESSION\",\"$SUSPECT\"]}" | jq '[.[].publishers[0]] | unique | length')
echo "participants=$all  reports_against_$(name $SUSPECT)=$against  rule: participants>=4 AND against>participants/2"

if [ "$all" -lt 4 ] || [ $((against*2)) -le "$all" ]; then
  echo "VERDICT: not enough evidence - no action"; exit 0
fi
echo "VERDICT: $(name $SUSPECT) is misbehaving"

echo "----- Punishment -----"
old=$(tv_of $SUSPECT); new=$((old-1))
RSU1 publish trust_updates $SUSPECT "{\"json\":{\"session\":\"$SESSION\",\"verdict\":\"misbehaving\",\"tv\":$new,\"by\":\"RSU1\"}}" > /dev/null
echo "$(name $SUSPECT) TV: $old -> $new"
if [ "$new" -lt 0 ]; then
  RSU1 revoke $SUSPECT send,receive > /dev/null
  RSU1 publish revocation_list $SUSPECT "{\"json\":{\"session\":\"$SESSION\",\"type\":\"hard\",\"tv\":$new}}" > /dev/null
  echo "HARD REVOCATION: send and receive revoked, added to revocation_list"
else
  h=$(RSU1 getblockcount)
  RSU1 grant $SUSPECT send 0 $((h+BLOCK_FOR)) 4294967295 > /dev/null
  echo "SOFT REVOCATION: send blocked until block $((h+BLOCK_FOR)) (now at block $h)"
fi

echo "----- Rewards -----"
alarmer=$(RSU1 liststreamkeyitems misbehaviour_reports $SESSION false 1 0 | jq -r '.[0].publishers[0]')
for r in $(RSU1 liststreamqueryitems misbehaviour_reports "{\"keys\":[\"$SESSION\",\"$SUSPECT\"]}" | jq -r '[.[].publishers[0]] | unique | .[]'); do
  RSU1 sendassetfrom $RSU1_ADDR $r IoVCredit 5 > /dev/null
  t=$(tv_of $r)
  RSU1 publish trust_updates $r "{\"json\":{\"session\":\"$SESSION\",\"verdict\":\"honest_reporter\",\"tv\":$((t+1)),\"by\":\"RSU1\"}}" > /dev/null
  echo "$(name $r): +5 IoVCredit, TV $t -> $((t+1))"
done
RSU1 sendwithdatafrom $RSU1_ADDR $alarmer '{"IoVCredit":2}' "{\"json\":{\"reason\":\"alarmer\",\"session\":\"$SESSION\"}}" > /dev/null
echo "$(name $alarmer): +2 IoVCredit extra (alarmer)"

echo "waiting for the next block..."
sleep 20

echo "===== Proof ====="
echo "----- V5 send permission window -----"
RA listpermissions send $SUSPECT | jq -r '.[] | "send  startblock=\(.startblock)  endblock=\(.endblock)"'
echo "current block: $(RA getblockcount)"
echo "----- V5 tries to publish while blocked (must FAIL) -----"
VEH publishfrom $SUSPECT region_events $SUSPECT '{"json":{"event":"test-while-blocked"}}' 2>&1
echo "----- Trust Values and balances (read from RSU3) -----"
for v in V1 V2 V3 V4 V5; do
  a=${!v}
  t=$(RSU3 liststreamkeyitems trust_updates $a false 1 | jq -r '.[0].data.json.tv // "2"')
  b=$(VEH getaddressbalances $a | jq -r '[.[] | select(.name=="IoVCredit") | .qty] | add // 0')
  echo "$v  TV=$t  IoVCredit=$b"
done
