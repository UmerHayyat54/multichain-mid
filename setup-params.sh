#!/bin/bash
# Step 2: create the regional chain and set params.dat
multichain-util create iovregionA

P=/root/.multichain/iovregionA/params.dat
setp() { sed -i "s|^$1 = .*|$1 = $2|" $P; }

setp chain-description "IoV Region A trust shard"
setp anyone-can-connect false
setp anyone-can-send false
setp anyone-can-receive false
setp anyone-can-receive-empty true
setp anyone-can-create false
setp anyone-can-issue false
setp anyone-can-mine false
setp anyone-can-activate false
setp anyone-can-admin false
setp root-stream-open false
setp mining-diversity 0.75
setp admin-consensus-admin 0.5
setp admin-consensus-mine 0.5
setp target-block-time 15
setp mining-requires-peers true
setp default-network-port 7451
setp default-rpc-port 7450

echo "----- Changed parameters -----"
grep -E "^(chain-description|anyone-can-|root-stream-open|mining-diversity|admin-consensus-admin|admin-consensus-mine|target-block-time|mining-requires-peers|default-network-port|default-rpc-port)" $P
