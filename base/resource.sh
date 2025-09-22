#!/bin/bash


set -euo pipefail

VALIDATOR_KEY=$(openssl rand -hex 32) # repalce with valid key
SIGNER_KEY=$(openssl rand -hex 32) # replace it with valid signer 

kubectl create secret generic validator-keys \
  --namespace=hyperliquid \
  --from-literal=validator-key=${VALIDATOR_KEY} \
  --from-literal=signer-key=${SIGNER_KEY}
