#!/usr/bin/env bash
# Install the multi-cluster Prometheus + Thanos + Grafana stack.
# Run the WORKLOAD section against each workload cluster's kube-context,
# and the CENTRAL section against the observability cluster's context.
set -euo pipefail

NS=monitoring

echo ">> Add Helm repos"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# --- Precondition (every cluster that talks to S3): create the objstore secret ---
# Copy objstore-secret.example.yaml -> objstore.yml, fill in bucket/region, then:
#   kubectl -n "$NS" create secret generic thanos-objstore --from-file=objstore.yml=./objstore.yml
echo ">> Ensure 'thanos-objstore' secret exists in namespace '$NS' before continuing."

# =========================================================================
# WORKLOAD CLUSTER  (repeat per cluster; edit externalLabels.cluster each time)
# =========================================================================
install_workload() {
  helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
    -n "$NS" --create-namespace \
    -f "$(dirname "$0")/values/workload-cluster.yaml"
}

# =========================================================================
# CENTRAL OBSERVABILITY CLUSTER  (once)
# =========================================================================
install_central() {
  helm upgrade --install thanos bitnami/thanos \
    -n "$NS" --create-namespace \
    -f "$(dirname "$0")/values/central-thanos.yaml"
}

case "${1:-}" in
  workload) install_workload ;;
  central)  install_central ;;
  *) echo "Usage: $0 {workload|central}"; exit 1 ;;
esac
