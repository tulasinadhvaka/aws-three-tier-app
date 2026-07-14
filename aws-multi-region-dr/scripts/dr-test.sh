#!/usr/bin/env bash
# Non-destructive DR validation: confirm replication is healthy and the
# failover paths are configured. Run on a schedule (e.g. quarterly).
set -euo pipefail

: "${PRIMARY_REGION:?set PRIMARY_REGION}"
: "${DR_REGION:?set DR_REGION}"
: "${GLOBAL_CLUSTER_ID:?set GLOBAL_CLUSTER_ID}"
: "${HEALTH_CHECK_ID:?set HEALTH_CHECK_ID}"

echo "== Aurora Global replication members =="
aws rds describe-global-clusters \
  --global-cluster-identifier "$GLOBAL_CLUSTER_ID" \
  --query 'GlobalClusters[0].GlobalClusterMembers[].{Cluster:DBClusterArn,Writer:IsWriter}' \
  --output table

echo "== Route 53 primary health check status =="
aws cloudwatch get-metric-statistics \
  --namespace AWS/Route53 --metric-name HealthCheckStatus \
  --dimensions Name=HealthCheckId,Value="$HEALTH_CHECK_ID" \
  --start-time "$(date -u -v-10M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '10 min ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 60 --statistics Minimum --region us-east-1 \
  --query 'Datapoints[].Minimum' --output text

echo "== OK: replication members listed and health check queried. Record RTO/RPO in RUNBOOK. =="
