#!/usr/bin/env bash
# Promote the Aurora DR cluster to a standalone writer during a regional failover.
# This detaches the DR cluster from the global cluster and makes it writable.
set -euo pipefail

: "${DR_REGION:?set DR_REGION (e.g. us-west-2)}"
: "${GLOBAL_CLUSTER_ID:?set GLOBAL_CLUSTER_ID}"
: "${DR_CLUSTER_ARN:?set DR_CLUSTER_ARN (arn of the DR cluster)}"

echo ">> Detaching DR cluster from global cluster (this promotes it to writer)…"
aws rds remove-from-global-cluster \
  --global-cluster-identifier "$GLOBAL_CLUSTER_ID" \
  --db-cluster-identifier "$DR_CLUSTER_ARN" \
  --region "$DR_REGION"

echo ">> Waiting for the DR cluster to become available as a writer…"
aws rds wait db-cluster-available \
  --db-cluster-identifier "$DR_CLUSTER_ARN" \
  --region "$DR_REGION"

echo ">> Done. Point application writes at the DR writer endpoint."
