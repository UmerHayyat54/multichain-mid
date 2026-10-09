#!/bin/bash
# Step 13: global chain iovglobal (TA + RA-global) and the LEAVE-REGION step for V1
source /work/iov.sh

echo "===== Creating iovglobal ====="
multichain-util create iovglobal > /dev/null
P=/root/.multichain/iovglobal/params.dat
setp() { sed -i "s|^$1 = .*|$1 = $2|" $P; }
setp chain-description "IoV global trust chain"
for f in connect send receive create issue mine activate admin; do setp anyone-can-$f false; done
setp root-stream-open false
setp mining-diversity 0.5
setp target-block-time 15
setp default-network-port 7551
setp default-rpc-port 7550
grep -E "^(chain-description|anyone-can-mine|mining-diversity|default-network-port)" $P

multichaind iovglobal -daemon > /dev/null
sleep 5

cat >> /work/iov.sh <<'EOF'
TA()  { multichain-cli -requestout=null iovglobal "$@"; }
RAG() { multichain-cli -requestout=null -datadir=/root/.mc-raglobal -rpcport=7560 iovglobal "$@"; }
EOF
source /work/iov.sh
echo "TA_ADDR=$(TA getaddresses | jq -r '.[0]')" >> /work/iov.sh

echo "===== RA-global joins iovglobal ====="
mkdir -p /root/.mc-raglobal
RAGA=$(multichaind iovglobal@127.0.0.1:7551 -datadir=/root/.mc-raglobal -port=7561 -rpcport=7560 2>&1 \
  | tee /work/join-raglobal.log | grep -oE 'grant [[:alnum:]]+' | head -1 | awk '{print $2}')
echo "RAG_ADDR=$RAGA" >> /work/iov.sh
source /work/iov.sh
TA grant $RAG_ADDR connect,send,receive,mine > /dev/null
multichaind iovglobal -datadir=/root/.mc-raglobal -port=7561 -rpcport=7560 -daemon > /dev/null
cat >> /work/start-all.sh <<'EOF'
multichaind iovglobal -daemon
sleep 3
multichaind iovglobal -datadir=/root/.mc-raglobal -port=7561 -rpcport=7560 -daemon
EOF
sleep 10

echo "===== trust_scores stream ====="
TA create stream trust_scores false > /dev/null
sleep 20
TA grant $RAG_ADDR trust_scores.write > /dev/null
TA subscribe trust_scores; RAG subscribe trust_scores
sleep 20

echo "===== LEAVE-REGION: V1 leaves Region A ====="
VEH publishfrom $V1 region_events $V1 '{"json":{"event":"LEAVE-REGION"}}' > /dev/null
sleep 20
TV1=$(RA liststreamkeyitems trust_updates $V1 false 1 | jq -r '.[0].data.json.tv // 2')
CR1=$(VEH getaddressbalances $V1 | jq -r '[.[] | select(.name=="IoVCredit") | .qty] | add // 0')
PSN=$(grep " $V1 " /work/ra-private-map.txt | awk '{print $3}')
ANCHOR=$(RA getbestblockhash)
AHEIGHT=$(RA getblock $ANCHOR | jq .height)
echo "RA looks up V1 -> $PSN (private map), TV=$TV1, IoVCredit=$CR1, regional block $AHEIGHT"
RAG publish trust_scores $PSN "{\"json\":{\"region\":\"A\",\"tv\":$TV1,\"credit\":$CR1,\"regional_block\":\"$ANCHOR\",\"regional_height\":$AHEIGHT}}" > /dev/null
RA publish vehicle_registry $V1 "{\"json\":{\"tv\":$TV1,\"status\":\"left_region\",\"region\":\"A\"}}" > /dev/null
sleep 20

echo "===== Global record (read by TA on iovglobal) ====="
TA liststreamkeyitems trust_scores $PSN | jq '.[] | {key: .keys[0], data: .data.json, confirmations}'
echo "===== Verify the anchor exists on the regional chain ====="
RA getblock $(TA liststreamkeyitems trust_scores $PSN | jq -r '.[0].data.json.regional_block') | jq '{hash, height, miner}'
echo "===== Two chains running ====="
echo "iovregionA blocks: $(RA getblockcount)   iovglobal blocks: $(TA getblockcount)"
