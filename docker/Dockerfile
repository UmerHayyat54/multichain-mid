# MultiChain 2.3.3 Community on Ubuntu 22.04, with the tools the scripts need (jq, bc, nano).
# Build (from the repo root):
#   docker build --platform linux/amd64 -t local-multichain:latest docker/
FROM ubuntu:22.04

ARG MC_VERSION=2.3.3
RUN apt-get update \
 && apt-get install -y --no-install-recommends wget ca-certificates jq bc nano \
 && wget -q https://www.multichain.com/download/multichain-${MC_VERSION}.tar.gz \
 && tar -xzf multichain-${MC_VERSION}.tar.gz \
 && mv multichain-${MC_VERSION}/multichaind multichain-${MC_VERSION}/multichain-cli \
       multichain-${MC_VERSION}/multichain-util /usr/local/bin/ \
 && rm -rf multichain-${MC_VERSION}* \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
CMD ["/bin/bash"]
