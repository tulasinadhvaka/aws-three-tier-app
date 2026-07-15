# Grafana Loki on Kubernetes with S3 Backend

Instructions to deploy Grafana Loki into a Kubernetes cluster using **S3 as the
chunk/index storage backend**, and to ship **Docker container logs from standalone
Docker hosts** (independent VMs, not part of the cluster) into Loki.

Loki runs via the official `grafana/loki` Helm chart in **SimpleScalable** mode
(read / write / backend targets). The cluster is a **plain Kubernetes cluster —
not EKS** — so Loki authenticates to S3 with **static access keys**. All files
referenced below live in this directory.

```
loki/
├── README.md              # this file
├── loki-values.yaml       # Helm values for Loki (S3 backend, static keys)
├── s3-policy.json         # IAM policy for the Loki S3 bucket
├── promtail-config.yaml   # Promtail config for a standalone Docker host
└── alloy-config.river     # Alloy config for a standalone Docker host (Promtail successor)
```

---

## Architecture at a glance

Log **sources are standalone Docker hosts** (independent VMs, *not* Kubernetes
nodes). Each host runs its own Promtail/Alloy agent as a container, tailing the
local Docker container logs and pushing to Loki's **externally-exposed** gateway.
Loki itself runs in Kubernetes with an S3 backend.

```
  Standalone Docker hosts (outside K8s)
 ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
 │  Docker host A│  │  Docker host B│  │  Docker host C│
 │ ┌───────────┐ │  │ ┌───────────┐ │  │ ┌───────────┐ │
 │ │containers │ │  │ │containers │ │  │ │containers │ │  logs →
 │ └─────┬─────┘ │  │ └─────┬─────┘ │  │ └─────┬─────┘ │  /var/lib/
 │ ┌─────▼─────┐ │  │ ┌─────▼─────┐ │  │ ┌─────▼─────┐ │  docker/
 │ │Promtail / │ │  │ │Promtail / │ │  │ │Promtail / │ │  containers
 │ │  Alloy    │ │  │ │  Alloy    │ │  │ │  Alloy    │ │  (1 agent
 │ └─────┬─────┘ │  │ └─────┬─────┘ │  │ └─────┬─────┘ │   per host)
 └───────┼───────┘  └───────┼───────┘  └───────┼───────┘
         │                  │                  │
         └──────────────────┼──────────────────┘
                            │  push over network (HTTPS)
                            │  to external gateway address
 ═══════════════════════════╪═══════════════ cluster boundary ═══
                            │
   Kubernetes cluster       │
 ┌──────────────────────────┼────────────────────────────────────┐
 │                   ┌──────▼───────┐                              │
 │   LoadBalancer /  │ loki-gateway │  nginx — ingest + query      │
 │   Ingress (auth,  │   (Service)  │  endpoint                    │
 │   TLS)            └──────┬───────┘                              │
 │            ┌─────────────┼─────────────┐                        │
 │        ┌───▼───┐     ┌───▼───┐     ┌────▼────┐                  │
 │        │ write │     │ read  │     │ backend │  SimpleScalable  │
 │        │ pods  │     │ pods  │     │  pods   │  targets         │
 │        └───┬───┘     └───┬───┘     └────┬────┘                  │
 │            │             │              │  static access keys   │
 │            │             │              │  (S3 secret)          │
 └────────────┼─────────────┼──────────────┼───────────────────────┘
              └─────────────┴──────────────┘
                            │ chunks + TSDB index
                     ┌──────▼───────┐
                     │   AWS  S3    │   single bucket
                     │   bucket     │   (chunks/ + index/)
                     └──────────────┘

  Queries:  Grafana / LogCLI ──▶ loki-gateway ──▶ read pods ──▶ S3
```

- **Each Docker host** runs one Promtail/Alloy agent (a container) that tails
  `/var/lib/docker/containers/*/*.log` and pushes to the gateway.
- The **gateway is exposed externally** (LoadBalancer/Ingress) and secured with
  auth + TLS, since sources reach it from outside the cluster.
- Loki pods authenticate to **S3 with static access keys** (no EKS/IRSA).
- **write / read / backend** pods are the SimpleScalable targets; all share one
  **S3 bucket** for chunks and the TSDB index.

---

## Prerequisites

| Tool | Purpose | Check |
|------|---------|-------|
| `kubectl` | talk to the cluster | `kubectl version --client` |
| `helm` (v3.9+) | install charts | `helm version` |
| AWS account + IAM | create S3 bucket & access keys | `aws sts get-caller-identity` |
| A running K8s cluster | run Loki | `kubectl get nodes` |
| Docker on each source host | run the log agent | `docker version` |

---

## Step 1 — Create the S3 bucket

Pick a globally-unique bucket name and a region.

```bash
export AWS_REGION=us-west-2
export LOKI_BUCKET=us-west-2-ts-loki-chunks

aws s3api create-bucket \
  --bucket "$LOKI_BUCKET" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION"

# Block public access (recommended)
aws s3api put-public-access-block \
  --bucket "$LOKI_BUCKET" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Enable default encryption
aws s3api put-bucket-encryption \
  --bucket "$LOKI_BUCKET" \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

> A single bucket is sufficient — Loki stores both chunks and the TSDB index in it
> under separate prefixes.

---

## Step 2 — Create S3 access keys and store them as a secret

The cluster is not on AWS, so Loki uses a dedicated IAM user's access keys. Create
the IAM policy from [`s3-policy.json`](s3-policy.json), attach it to a new user,
generate an access key, and store the key as a Kubernetes secret.

```bash
# Policy that grants access to the bucket
aws iam create-policy \
  --policy-name LokiS3Access \
  --policy-document file://s3-policy.json

export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Dedicated IAM user for Loki
aws iam create-user --user-name loki-s3
aws iam attach-user-policy \
  --user-name loki-s3 \
  --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/LokiS3Access"
aws iam create-access-key --user-name loki-s3   # note the AccessKeyId + SecretAccessKey

# Store the keys as a secret Loki pods will read
kubectl create namespace loki 2>/dev/null || true
kubectl -n loki create secret generic loki-s3-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=<KEY> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<SECRET>
```

---

## Step 3 — Install Loki

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Edit loki-values.yaml first: set bucket name and region.
helm upgrade --install loki grafana/loki \
  --namespace loki \
  --values loki-values.yaml
```

Verify:

```bash
kubectl -n loki get pods
# read-*, write-*, backend-*, gateway-* pods should reach Running/Ready

# Confirm S3 connectivity — write pods should start flushing chunks.
# Check for storage/credential errors:
kubectl -n loki logs -l app.kubernetes.io/component=write --tail=50 | grep -i s3
```

The Loki gateway (nginx) is the ingest + query endpoint, reachable in-cluster at:

```
http://loki-gateway.loki.svc.cluster.local/
```

---

## Step 4 — Expose the gateway to the Docker hosts

The Docker hosts are outside the cluster, so they need a reachable, secured
address for the gateway. Expose it with a LoadBalancer (or an Ingress) and put
auth + TLS in front of it.

```bash
# Simplest: a LoadBalancer service for the gateway
kubectl -n loki patch svc loki-gateway \
  -p '{"spec":{"type":"LoadBalancer"}}'

kubectl -n loki get svc loki-gateway   # note the EXTERNAL-IP / hostname
```

Record the external address — call it `LOKI_GATEWAY` below, e.g.
`https://loki.example.com`. **Do not expose it without auth/TLS**; anyone who can
reach it can write and read logs.

---

## Step 5 — Ship Docker container logs from each host

On a standalone Docker host, container logs are JSON files under
`/var/lib/docker/containers/<id>/<id>-json.log`. Run **one agent per host** as a
container that mounts that directory read-only and pushes to `LOKI_GATEWAY`.
Pick **one** of the two agents.

### Option 1 — Promtail (simple, stable)

Edit [`promtail-config.yaml`](promtail-config.yaml) — set the `clients[0].url` to
`https://<LOKI_GATEWAY>/loki/api/v1/push` — then run:

```bash
docker run -d --name promtail --restart unless-stopped \
  -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v "$PWD/promtail-config.yaml:/etc/promtail/config.yaml:ro" \
  grafana/promtail:latest \
  -config.file=/etc/promtail/config.yaml
```

### Option 2 — Grafana Alloy (Promtail's successor, recommended for new setups)

Edit [`alloy-config.river`](alloy-config.river) — set the `loki.write` endpoint
`url` to `https://<LOKI_GATEWAY>/loki/api/v1/push` — then run:

```bash
docker run -d --name alloy --restart unless-stopped \
  -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v "$PWD/alloy-config.river:/etc/alloy/config.river:ro" \
  grafana/alloy:latest \
  run /etc/alloy/config.river
```

Both discover the host's containers via the Docker socket, tail their log files,
attach labels (`host`, `container`, `image`), and push to the gateway. Repeat on
every Docker host.

---

## Step 6 — Query the logs

Add Loki as a Grafana data source (URL = your `LOKI_GATEWAY`), or use LogCLI
directly against the external address:

```bash
export LOKI_ADDR=https://<LOKI_GATEWAY>
logcli query '{host="docker-host-a"}' --limit=20
logcli query '{container="nginx"} |= "error"'
```

In Grafana → Explore → Loki, try:

```logql
{host="docker-host-a"} |= "error"
count_over_time({container="nginx"}[5m])
```

---

## Retention & housekeeping

`loki-values.yaml` sets a 30-day retention via the compactor. To change it, edit
`limits_config.retention_period` and the compactor's `retention_enabled`. S3
lifecycle rules can be added as a backstop, but let Loki's compactor manage
deletion so the index stays consistent.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| write pods `CrashLoopBackOff`, `AccessDenied` in logs | `loki-s3-credentials` secret missing/wrong, or policy not attached to the IAM user |
| `NoSuchBucket` | wrong bucket name/region in `loki-values.yaml` |
| Agent runs but no logs in Loki | wrong `LOKI_GATEWAY` URL, or `/var/lib/docker/containers` not mounted |
| Agent can't reach gateway (timeout/TLS) | gateway not exposed externally, firewall, or bad cert |
| `429 / rate limited` | raise `limits_config.ingestion_rate_mb` in Loki values |
| high S3 cost | too-small chunks; tune `chunk_target_size` / retention |
