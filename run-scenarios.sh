#!/usr/bin/env bash
set -eu
echo "--- context: $(kubectl config current-context) ---"

echo "=== 1) broker-allowed -> widget-1 ==="
BROKER_NAMESPACE=demo BROKER_SA=broker-allowed \
  OBJ_GROUP=example.io OBJ_RESOURCE=widgets OBJ_NAMESPACE=demo OBJ_NAME=widget-1 \
  ./check

echo
echo "=== 2) broker-allowed -> widget-2 ==="
BROKER_NAMESPACE=demo BROKER_SA=broker-allowed \
  OBJ_GROUP=example.io OBJ_RESOURCE=widgets OBJ_NAMESPACE=demo OBJ_NAME=widget-2 \
  ./check

echo
echo "=== 3) broker-denied -> widget-1 ==="
BROKER_NAMESPACE=demo BROKER_SA=broker-denied \
  OBJ_GROUP=example.io OBJ_RESOURCE=widgets OBJ_NAMESPACE=demo OBJ_NAME=widget-1 \
  ./check

echo
echo "=== 4) broker-allowed -> widget in 'other' ns ==="
BROKER_NAMESPACE=demo BROKER_SA=broker-allowed \
  OBJ_GROUP=example.io OBJ_RESOURCE=widgets OBJ_NAMESPACE=other OBJ_NAME=widget-1 \
  ./check
