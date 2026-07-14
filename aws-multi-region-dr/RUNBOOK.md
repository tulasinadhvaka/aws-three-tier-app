# Disaster Recovery Runbook — Multi-Region Failover

Procedures for failing over to the DR region, validating, and failing back.
Targets: **RTO ≤ 30 min**, **RPO ≤ 5 min** (databases).

## 0. Environment
```bash
PRIMARY_REGION=$(terraform -chdir=environments/dev output -raw ... )   # or set manually
DR_REGION=us-west-2
GLOBAL_CLUSTER_ID=$(terraform -chdir=environments/dev output -raw aurora_dr_cluster_id) # see outputs
HEALTH_CHECK_ID=<from module.route53.primary_health_check_id>
```

## 1. Detect
- CloudWatch alarm `*-primary-region-unhealthy` fires → SNS notifies.
- CloudFront already serving DR origin (origin-group failover, automatic, seconds).
- Route 53 begins answering with the SECONDARY record once the health check crosses threshold.

## 2. Fail over the data tier
**Aurora (promote DR to writer):**
```bash
export DR_REGION GLOBAL_CLUSTER_ID
export DR_CLUSTER_ARN=<arn of the DR cluster>
./scripts/promote-aurora.sh
```
**Redis (promote DR secondary):**
```bash
aws elasticache failover-global-replication-group \
  --global-replication-group-id <global-id> \
  --primary-region "$DR_REGION" \
  --primary-replication-group-id <dr-rg-id>
```

## 3. Cut application over
- Point app config / secrets at the DR Aurora **writer** endpoint and DR Redis endpoint.
- Confirm CloudFront + Route 53 are serving DR (they should already be).

## 4. Validate
```bash
export PRIMARY_REGION DR_REGION GLOBAL_CLUSTER_ID HEALTH_CHECK_ID
./scripts/dr-test.sh
curl -sf https://<cloudfront_domain>/healthz
```
Record actual **RTO** (incident → serving from DR) and **RPO** (replication lag at failover).

## 5. Fail back (after primary recovers)
1. Rebuild/rejoin the original primary as a secondary of the (now-DR) global cluster; let it catch up.
2. Schedule a maintenance window; promote the original primary back.
3. Re-point CloudFront/Route 53; verify health check green.
4. Resume normal replication direction.

## 6. Quarterly DR test (checklist)
- [ ] Run `scripts/dr-test.sh` — replication members + health check queried.
- [ ] Confirm Aurora Global lag < 5 min and Redis global healthy.
- [ ] Simulate primary failure (e.g. block ALB health path) in a test window.
- [ ] Verify CloudFront serves DR origin and Route 53 flips.
- [ ] Record RTO / RPO below; file gaps as follow-ups.

| Date | RTO achieved | RPO achieved | Notes |
|------|--------------|--------------|-------|
|      |              |              |       |
