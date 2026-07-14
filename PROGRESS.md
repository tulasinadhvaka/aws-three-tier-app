# Portfolio Progress

Tracking file for the Portfolio agent. Ship one project fully (all "done" boxes checked) before starting the next.

## Project order (easy → hard)
| # | Project | Status | Repo | Demonstrates |
|---|---------|--------|------|--------------|
| 1 | AWS production infra with Terraform | 🟡 In progress | `aws-terraform-foundation/` | IaC, VPC design, IAM, remote state, multi-env |
| 2 | Three-tier app on AWS | 🟡 In progress | `aws-three-tier-app/` | ALB, ASG autoscaling, layered SGs, Multi-AZ RDS |
| 3 | EKS cluster + multiple node groups | 🟡 In progress | `aws-eks-cluster/` | EKS, IRSA/OIDC, on-demand + Spot + tainted node groups |
| 4 | Multi-cluster monitoring (Prometheus/Thanos/Grafana) | 🟡 In progress | `k8s-monitoring-thanos/` | Helm, Thanos sidecar+hub, S3 long-term storage, IRSA |
| 5 | CI/CD pipeline (GitHub Actions) | 🟡 In progress | `cicd-github-actions/` | build→test→scan→deploy, OIDC, env gates, ECR→EKS |
| 6 | Multi-region DR (active/passive failover) | 🟡 In progress | `aws-multi-region-dr/` | Aurora Global, Redis Global, S3 CRR, CloudFront+Route53 failover, RTO≤30m/RPO≤5m |

Legend: ⚪ Not started · 🟡 In progress · 🟢 Done

## "Done" checklist (per project)
- [ ] Working, `terraform validate` / `plan`-clean IaC
- [ ] Architecture diagram (Mermaid)
- [ ] README (problem, architecture, deploy, teardown, what it demonstrates)
- [ ] Deployment instructions a stranger can follow
- [ ] Screenshots / terminal output as evidence
- [ ] Outcomes line
- [ ] `.gitignore`, no secrets, teardown/cost note

## Current focus: Project #1 — AWS Terraform Foundation
- [x] Scaffold module structure
- [x] VPC module (public/private subnets, NAT, IGW, route tables)
- [x] Remote state backend (S3 + DynamoDB lock) config
- [x] IAM baseline
- [x] Multi-env via `environments/` (dev/staging/prod)
- [x] README + architecture diagram
- [x] `.gitignore` + teardown notes
- [ ] Run `terraform init/validate/plan` against a real AWS account (needs your creds)
- [ ] Add screenshots after first apply

## Project #2 — Three-Tier App (aws-three-tier-app)
- [x] ALB module (internet-facing, HTTP :80, target group, health checks)
- [x] App module (launch template + ASG, SG scoped to ALB only, SSM-ready)
- [x] Database module (Multi-AZ RDS, encrypted, SG scoped to app tier only, not public)
- [x] dev environment wiring all three tiers + layered security groups
- [x] README + Mermaid diagram + terraform.tfvars.example
- [x] `terraform fmt/init/validate` all pass
- [ ] Run `apply` against a real AWS account (needs VPC/subnet IDs + db_password)
- [ ] Screenshot the working app via the ALB DNS name

## Project #3 — EKS Cluster (aws-eks-cluster)
- [x] eks-cluster module (control plane, cluster IAM role, OIDC provider for IRSA, core add-ons)
- [x] eks-node-group reusable module (node IAM role, labels, taints, capacity type)
- [x] dev env: 3 node groups — general (on-demand), spot (multi-type), system (tainted, optional)
- [x] README + Mermaid diagram + terraform.tfvars.example
- [x] `terraform fmt/init/validate` all pass
- [ ] Run `apply` against a real AWS account (needs private_subnet_ids + NAT enabled)
- [ ] `kubectl get nodes --show-labels` screenshot showing all node groups joined

## Project #4 — Multi-Cluster Monitoring (k8s-monitoring-thanos)
- [x] Architecture: sidecar-on-edge + central hub (store/query/compact + Grafana), S3 long-term
- [x] workload-cluster.yaml — kube-prometheus-stack + Thanos sidecar, unique cluster labels, IRSA
- [x] central-thanos.yaml — querier, query-frontend, storegateway, compactor (one/bucket)
- [x] objstore-secret.example.yaml — S3 config via IRSA (aws_sdk_auth, SSE-S3, no static keys)
- [x] install.sh (workload/central) + multicluster-overview.json Grafana dashboard
- [x] `helm template` renders clean (21 resources); IRSA verified on storegateway + compactor SAs
- [ ] Provision S3 bucket + IRSA role (out-of-band; extend Project #3) — needed before install
- [ ] Deploy against >= 2 real clusters; screenshot Grafana querying across clusters

## Project #5 — CI/CD Pipeline (cicd-github-actions)
- [x] ci.yml — lint (ruff+hadolint), test (pytest+coverage gate 80%), scan (bandit+pip-audit)
- [x] cd.yml — build → Trivy image scan → push ECR → deploy staging → approval gate → prod
- [x] Composite action (aws-ecr-login) — GitHub OIDC, no stored secrets
- [x] Flask app + tests, multi-stage non-root Dockerfile, hardened k8s manifests
- [x] VERIFIED LOCALLY: ruff clean, pytest 2/2 @ 96% cov, bandit clean, pip-audit clean, docker build OK
- [x] pip-audit caught a real Flask CVE → bumped 3.0.3→3.1.3 (dependency-scan gate working as intended)
- [ ] Wire GitHub repo: OIDC IAM role, repo variables, staging/production Environments
- [ ] Screenshot a green pipeline run (Actions tab) + prod approval gate

## Project #6 — Multi-Region DR / active-passive failover (aws-multi-region-dr)
Rearchitected per CLAUDE.md from backup-restore → full multi-region failover (RTO≤30m, RPO≤5m).
- [x] 8 region-agnostic modules: network, alb, aurora-global, redis-global, s3-replication, cloudfront, route53, monitoring
- [x] Aurora Global Database (primary writer + DR reader, continuous <1s replication → RPO≤5m)
- [x] ElastiCache Global Datastore (primary + DR secondary)
- [x] S3 Cross-Region Replication with versioning + IAM replication role
- [x] CloudFront origin-group failover (primary + DR origins, 5xx/timeout → DR)
- [x] Route53 health check + PRIMARY/SECONDARY failover ALIAS records
- [x] CloudWatch alarm (us-east-1 for R53 metrics) + dashboard + SNS
- [x] dev env: 3 providers (primary, aws.dr, aws.useast1), no hardcoded regions/names
- [x] scripts: promote-aurora.sh, dr-test.sh + RUNBOOK (failover/failback/quarterly test)
- [x] `terraform fmt/init/validate` all pass, ZERO warnings (added providers.tf to all modules)
- [ ] Run `apply` against a real AWS account (warm-standby footprint — NOT free tier)
- [ ] Execute a failover test per RUNBOOK; record actual RTO/RPO; screenshots

## Next action
Six projects validate cleanly (#5 verified end-to-end locally). When AWS creds are ready:
1. Apply Project #1 (`aws-terraform-foundation/environments/dev`). For #3, enable NAT
   (`enable_nat_gateway = true`) so private nodes can pull images.
2. Feed the foundation's `vpc_id` + subnet outputs into #2 and #3's `terraform.tfvars`.
3. Apply, then capture screenshots (app page for #2, `kubectl get nodes` for #3).

Note: Prometheus/Grafana monitoring is now a separate Project #4 (Helm on top of the #3 cluster).
