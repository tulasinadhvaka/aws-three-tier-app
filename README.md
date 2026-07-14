# AWS Infrastructure Engineering Portfolio

Production-shaped cloud infrastructure and delivery projects — **Terraform · AWS · EKS/Kubernetes · CI/CD**. Each project is self-contained, documented with an architecture diagram, secrets-safe, and validated (`terraform validate` / `helm template` / full CI gate) before it's called done.

> **Positioning:** AWS Infrastructure Engineer — I build reproducible, production-ready cloud infrastructure and automated delivery pipelines, as code.

## At a glance

| # | Project | Status | What it demonstrates | Stack |
|---|---------|--------|----------------------|-------|
| 1 | [AWS Terraform Foundation](./aws-terraform-foundation) | ✅ Built · validate-clean | Reusable multi-env network foundation | Terraform · AWS |
| 2 | [Three-Tier App on AWS](./aws-three-tier-app) | ✅ Built · validate-clean | ALB → autoscaling app → Multi-AZ RDS, layered SGs | Terraform · ALB · ASG · RDS |
| 3 | [EKS Cluster](./aws-eks-cluster) | ✅ Built · validate-clean | EKS with on-demand + Spot + tainted node groups, IRSA | Terraform · EKS |
| 4 | [Multi-Cluster Monitoring](./k8s-monitoring-thanos) | ✅ Built · render-clean | Prometheus + Thanos + Grafana, S3 long-term storage | Helm · Thanos · S3 |
| 5 | [CI/CD Pipeline](./cicd-github-actions) | ✅ Built · verified locally | build → test → scan → deploy, OIDC, env gates | GitHub Actions · Trivy · OIDC |
| 6 | [Multi-Region Disaster Recovery](./aws-multi-region-dr) | ✅ Built · validate-clean | Active/passive failover — Aurora Global, CloudFront + Route 53 failover, RTO≤30m/RPO≤5m | Terraform · Aurora Global · CloudFront · Route 53 |

Status legend: ✅ built & validated locally (pending a live-account `apply` + screenshots) · ⬜ planned.

---

## Built projects

### 1. AWS Terraform Foundation — [`aws-terraform-foundation/`](./aws-terraform-foundation)
A secure, multi-AZ AWS network foundation provisioned entirely with Terraform, reusable across `dev`, `staging`, and `prod`.

- **Modules:** reusable `vpc` (public/private subnets, IGW, NAT, route tables) and `iam` (least-privilege EC2 baseline using SSM — no open SSH).
- **Multi-environment:** `environments/{dev,staging,prod}` with isolated CIDRs (`10.0/10.1/10.2`) and per-env remote-state backend config (S3 + DynamoDB lock).
- **Cost-aware:** NAT disabled in `dev` by default (free); enabled in staging/prod.
- **Verified:** `terraform fmt/init/validate` clean across all three environments.

### 2. Three-Tier App on AWS — [`aws-three-tier-app/`](./aws-three-tier-app)
The classic web → app → data architecture, showcasing layered network security.

- **Tiers:** internet-facing ALB → Auto Scaling Group in private subnets → Multi-AZ encrypted RDS.
- **Layered security groups:** ALB open to the internet; app tier accepts traffic **only from the ALB SG**; RDS accepts **only from the app SG** and is never public.
- **Secrets-safe:** `db_password` is `sensitive`, supplied via gitignored tfvars / `TF_VAR_`.
- **Composable:** takes `vpc_id` + subnet IDs as inputs — consumes Project #1's outputs directly.
- **Verified:** `terraform fmt/init/validate` clean.

### 3. EKS Cluster — [`aws-eks-cluster/`](./aws-eks-cluster)
A production-shaped Amazon EKS cluster with a real node-group strategy.

- **Multiple managed node groups** from one reusable module: `general` (on-demand), `spot` (multi-instance-type, cost-optimised), and an optional tainted `system` group for workload isolation.
- **IRSA:** cluster OIDC provider wired up so pods get least-privilege AWS access without node-wide credentials.
- **Add-ons as code:** VPC CNI, CoreDNS, kube-proxy. `ignore_changes` on desired size so a future Cluster Autoscaler won't fight Terraform.
- **Verified:** `terraform fmt/init/validate` clean.

### 4. Multi-Cluster Monitoring — [`k8s-monitoring-thanos/`](./k8s-monitoring-thanos)
Unified metrics across many Kubernetes clusters with long-term retention in S3.

- **Topology:** each workload cluster runs Prometheus + a **Thanos sidecar** shipping blocks to S3; a central cluster runs Thanos **Store Gateway + Querier + Compactor + Grafana** for one global query surface.
- **S3 long-term storage** via IRSA (`aws_sdk_auth`, SSE-S3 — no static keys in-cluster).
- **Correctness details:** exactly one Compactor per bucket; unique `cluster`/`replica` external labels for dedup; short local retention with history offloaded to S3.
- **Verified:** `helm template` renders clean (21 resources); IRSA confirmed on the storegateway + compactor service accounts.

### 5. CI/CD Pipeline — [`cicd-github-actions/`](./cicd-github-actions)
A full GitHub Actions pipeline: **build → test → scan → deploy**.

- **CI (PR/push):** ruff + hadolint lint, pytest with an 80% coverage gate, bandit SAST, pip-audit dependency scan.
- **CD (main):** build → Trivy image scan (fail on HIGH/CRITICAL) → push to ECR → deploy to staging (auto) → **manual approval gate** → prod.
- **Keyless AWS:** GitHub **OIDC** role assumption — no stored secrets. Reusable composite action for OIDC + ECR login.
- **Hardened runtime:** multi-stage non-root Dockerfile; k8s Deployment with read-only rootfs, dropped capabilities, and health probes.
- **Verified end-to-end locally:** ruff clean · pytest 2/2 @ 96% coverage · bandit clean · pip-audit clean · docker build OK. (pip-audit caught a real Flask CVE mid-build → dependency bumped; the gate works.)

---

### 6. Multi-Region Disaster Recovery — [`aws-multi-region-dr/`](./aws-multi-region-dr)
An **active/passive multi-region failover** architecture — the full stack in a primary and a warm-standby DR region, with automatic failover and continuous replication. Meets **RTO ≤ 30 min** and **RPO ≤ 5 min**.

- **8 region-agnostic Terraform modules** — network, ALB, Aurora Global, Redis Global, S3 CRR, CloudFront, Route 53, monitoring. No hardcoded regions or names; everything flows from `primary_region` / `dr_region`.
- **Continuous data replication:** Aurora Global Database (writer + promotable DR reader, < 1s lag), ElastiCache Global Datastore, and S3 Cross-Region Replication.
- **Automatic failover:** CloudFront **origin-group** failover at the edge (seconds) + Route 53 **health-check failover records** at DNS.
- **Operational tooling:** CloudWatch alarm + dashboard, SNS alerts, DR automation scripts (`promote-aurora.sh`, `dr-test.sh`), and a [**failover/failback runbook**](./aws-multi-region-dr/RUNBOOK.md) with a quarterly DR-test checklist recording actual RTO/RPO.
- **Well-Architected (Reliability):** multi-region, multi-AZ, automatic failover, idempotent IaC.
- **Verified:** `terraform fmt/init/validate` clean with **zero warnings** across a 3-provider (primary / DR / us-east-1) composition.

> Multi-environment promotion (dev/staging/prod) is already demonstrated in Project #1's `environments/` structure, so it isn't tracked as a separate build.

---

## Conventions across every project
- **Infrastructure as code** — no click-ops; reusable modules over copy-paste.
- **Security by default** — least-privilege IAM/IRSA, private data tiers, layered security groups, no secrets in git.
- **Cost-aware** — cost drivers called out, teardown steps in every README, cheap defaults for demos.
- **Validated** — nothing is marked done until it passes its toolchain's validation.
- **Documented** — every project has a Mermaid architecture diagram, deploy + teardown steps, and an outcomes line.

## Status & next steps
All five built projects validate cleanly locally. The remaining work for each is a live-AWS-account `apply` plus evidence screenshots — see [`PROGRESS.md`](./PROGRESS.md) for the per-project checklist and current focus.
