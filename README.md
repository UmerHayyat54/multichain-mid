# Adaptive Trust Management in IoV on MultiChain

Re-implementation of **"Blockchain-Based Adaptive Trust Management in Internet of Vehicles Using Smart Contract"** (Singh et al., IEEE T-ITS 2020, [DOI 10.1109/TITS.2020.3004041](https://doi.org/10.1109/TITS.2020.3004041)) on **MultiChain 2.3.3**, replacing the paper's Ethereum Proof-of-Work chain and Solidity contract with MultiChain chains, permissions, streams, an asset and a smart filter.

Future directions from the paper addressed here:
- **Efficient consensus at the RSU plane:** permissioned round-robin mining (`mining-diversity`) instead of PoW.
- **Plausibility checks on reports:** a smart filter rejects self-reports, impossible speeds and out-of-region positions before they reach the ledger.
- **Privacy (partial):** per-region vehicle addresses; the pseudonym map stays off-chain with the Regional Authority.

## How the paper maps to MultiChain

| Paper (Ethereum) | This implementation (MultiChain) |
|---|---|
| Regional shard | Chain `iovregionA` |
| Global chain (TA, CA, RAs) | Chain `iovglobal` |
| Regional Authority (RA) | Genesis admin node of `iovregionA` |
| RSUs (miners) | Nodes RSU1-RSU3 with `mine` + `admin` |
| Vehicles (light nodes) | Addresses V1-V5 on a non-mining vehicle node |
| Registers VR, PTR, SSR, VISR, CR | Streams `vehicle_registry`, `misbehaviour_reports`, `trust_updates`, `revocation_list`, `region_events` |
| `reportSuspicion()` checks | Smart filter `reportFilter.js` |
| `analyseReports()` (majority rule) | `step10-analyse.sh`, run by RSU1 |
| Ether reward / `claimReward()` | Asset `IoVCredit` |
| Soft revocation (blocked for a while) | Timed `grant` of `send` (6 blocks) |
| Hard revocation (TV < 0) | `revoke send,receive` + `revocation_list` |
| LEAVE-REGION to global chain | `trust_scores` stream on `iovglobal`, anchored by a regional block hash |

## Requirements

- Docker (tested with Docker Desktop on macOS)
- About 25 minutes for a full run (the scripts wait for 15-second blocks)

## Quick start

```bash
git clone https://github.com/UmerHayyat54/multichain-mid.git
cd multichain-mid

# 1. build the image (MultiChain 2.3.3 + jq, bc, nano)
docker build --platform linux/amd64 -t local-multichain:latest docker/

# 2. start a container with this folder mounted at /work
docker run -dit --name iov-midterm --platform linux/amd64 \
  -v "$PWD":/work -w /work --entrypoint /bin/bash local-multichain:latest
docker exec -it iov-midterm bash

# 3. inside the container: run every step in order
bash run-all.sh              # or: bash run-all.sh --no-bench
```

All nodes run inside one container, each with its own data directory and ports, and connect over `127.0.0.1`.

## Running step by step

Run these inside the container from `/work`, in order:

| Step | Script | What it does |
|---|---|---|
| 2 | `setup-params.sh` | Creates `iovregionA` and sets 18 `params.dat` values (closed permissions, `mining-diversity 0.75`, 15 s blocks, ports 7451/7450) |
| 3 | `step3-ra.sh` | Starts the RA node and writes helper commands to `iov.sh` |
| 4 | `step4-join.sh` | RSU1-RSU3 and the vehicle node connect and wait for permission |
| 5 | `step5-grant.sh` | RA grants `mine`/`admin` to RSUs and `connect` to the vehicle node, then starts them |
| 6 | `step6-streams.sh` | Creates V1-V5, the five streams and their write permissions |
| 7 | `step7-asset.sh` | Issues 100,000 IoVCredit, funds RSU1 with 1,000, registers vehicles with TV = 2 |
| 8 | `step8-filter.sh` | Compiles, creates and approves `reportFilter.js` on `misbehaviour_reports` |
| 9 | `step9-reports.sh` | Session S-101: V1-V4 report V5; three invalid reports are rejected |
| 10 | `step10-analyse.sh` | Majority verdict, soft revocation of V5, rewards for honest reporters |
| 11 | `step11-hard.sh` | Sessions S-102 and S-103 push V5 below TV 0: hard revocation |
| 12 | `step12-rotation.sh` | Shows miner rotation after the 60-block setup phase |
| 13 | `step13-global.sh` | Creates `iovglobal` and records V1's final score on LEAVE-REGION |
| 14 | `step14-bench.sh` | Sends 1, 100, 500, 750 and 1,000 reports and measures confirmation time |

From Step 3 onward, load the helper commands in your shell with `source iov.sh`. Then you can query any node, for example `RA liststreams` or `RSU2 getinfo`.

## Restarting after a container stop

Chain data is kept, but the daemons stop with the container:

```bash
docker start iov-midterm
docker exec -it iov-midterm bash
source /work/iov.sh && bash /work/start-all.sh
```

To start over from scratch, remove the container (`docker rm -f iov-midterm`) and run the Quick start again.

## Results

| Check | Result |
|---|---|
| Valid reports (S-101) | 4 accepted |
| Smart filter | Self-report, 900 km/h and out-of-region reports rejected (error -701) |
| Verdict | 4 participants, 4 against V5: misbehaving |
| Soft revocation | V5 cannot publish for 6 blocks ("from-address doesn't have send permission") |
| Rewards | V1 7 IoVCredit (alarmer), V2-V4 5 each after S-101 |
| Hard revocation | V5 TV -1, no permissions, listed in `revocation_list` |
| Consensus | After block 60, every 3 consecutive blocks have 3 different miners |
| Global chain | PSN-0001 (TV 5, 21 IoVCredit) on `iovglobal`, anchored to regional block 111 |
| Throughput | 1,000 reports confirmed in 111.28 s (8.98 tx/s), 0 failed |

Details: [`results/`](results/). Screenshots of every step: [`docs/screenshots/`](docs/screenshots/).

## Repository structure

```
├── setup-params.sh, step3-ra.sh ... step14-bench.sh   implementation steps
├── reportFilter.js     smart filter (plausibility checks)
├── run-all.sh          runs all steps in order
├── docker/Dockerfile   MultiChain 2.3.3 image
├── results/            benchmark output
├── docs/screenshots/   output of each step
└── paper/              citation of the selected paper
```

Files created at run time (`iov.sh`, `start-all.sh`, `ra-private-map.txt`, `join-*.log`, `run.log`) hold node addresses and are not committed.

## Known limitations

- The benchmark is limited by starting one `multichain-cli` process per report, not by consensus.
- Mining diversity is not enforced during MultiChain's first 60 blocks (`setup-first-blocks`).
- The majority rule runs off-chain at the RSU, since stream filters cannot read other stream items.
- Stream data is readable by every node on a chain (MultiChain Community has no read-restricted streams).
- All nodes run in one container, so real network latency is not reproduced.
