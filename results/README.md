# Results

Output of `step14-bench.sh` from our run (4 miners: RA + RSU1-RSU3, block time 15 s). Running the script writes the raw values to `bench-4miners.csv` in the repo root.

| Reports (N) | Submit time (s) | Total time to confirm (s) | Throughput (tx/s) | Failed |
|---|---|---|---|---|
| 1 | 0.12 | 8.29 | 0.12 | 0 |
| 100 | 10.71 | 20.03 | 4.99 | 0 |
| 500 | 53.41 | 57.20 | 8.74 | 0 |
| 750 | 80.19 | 86.46 | 8.67 | 0 |
| 1000 | 106.87 | 111.28 | 8.98 | 0 |

Paper (private Ethereum, PoW, 4 miners): 1000 transactions in 87.21 s = 11.47 tx/s.

Screenshots of every step are in [`../docs/screenshots`](../docs/screenshots).
