#!/bin/bash
set -e

CLUSTER_NAME="iotbonus"
GITEA_ADMIN_USER="${GITEA_ADMIN_USER:-gitea_admin}"
GITEA_ADMIN_PASSWORD="${GITEA_ADMIN_PASSWORD:-Password42!}"
GITEA_ADMIN_EMAIL="${GITEA_ADMIN_EMAIL:-admin@gitea.local}"
GITEA_HOST="gitea.localhost"
GITEA_URL="http://${GITEA_HOST}:8081"
SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
WORKDIR="/tmp/iot-bonus-playground"

echo "[INFO] Installing dependencies..."
apt-get update -qq
apt-get install -y -qq curl git

install_docker() {
  echo "[INFO] Installing Docker..."
  if command -v docker >/dev/null 2>&1; then
    echo "[INFO] Docker is already installed - skipping"
  else
    curl -fsSL https://get.docker.com | sh
  fi
}

install_kubectl() {
  echo "[INFO] Installing kubectl..."
  if command -v kubectl >/dev/null 2>&1; then
    echo "[INFO] kubectl is already installed - skipping"
  else
    curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/kubectl
  fi
}

install_k3d() {
  echo "[INFO] Installing K3d..."
  if command -v k3d >/dev/null 2>&1; then
    echo "[INFO] k3d is already installed - skipping"
  else
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  fi
}

install_helm() {
  echo "[INFO] Installing Helm..."
  if command -v helm >/dev/null 2>&1; then
    echo "[INFO] Helm is already installed - skipping"
  else
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
}

create_cluster() {
  echo "[INFO] Creating K3d bonus cluster..."
  if k3d cluster list | grep -q "^${CLUSTER_NAME}\b" 2>/dev/null; then
    echo "[INFO] k3d cluster '${CLUSTER_NAME}' already exists - skipping creation"
  else
    k3d cluster create "${CLUSTER_NAME}" \
      --port "8888:8888@loadbalancer" \
      --port "8081:80@loadbalancer"
  fi

  until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
    echo "   still waiting for Kubernetes..."
    sleep 5
  done
}

ensure_hosts_entry() {
  if ! grep -q "[[:space:]]${GITEA_HOST}$" /etc/hosts; then
    echo "[INFO] Adding ${GITEA_HOST} to /etc/hosts..."
    echo "127.0.0.1 ${GITEA_HOST}" >> /etc/hosts
  fi
}

install_argocd() {
  echo "[INFO] Installing Argo CD..."
  kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd
  kubectl get namespace dev >/dev/null 2>&1 || kubectl create namespace dev

  kubectl apply -n argocd \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
    --server-side \
    --force-conflicts

  kubectl wait --for=condition=available \
    deployment/argocd-server \
    -n argocd \
    --timeout=300s
}

install_gitea() {
  echo "[INFO] Installing Gitea in namespace gitea..."
  kubectl get namespace gitea >/dev/null 2>&1 || kubectl create namespace gitea

  if ! kubectl get secret gitea-admin-secret -n gitea >/dev/null 2>&1; then
    kubectl create secret generic gitea-admin-secret \
      -n gitea \
      --from-literal=username="${GITEA_ADMIN_USER}" \
      --from-literal=password="${GITEA_ADMIN_PASSWORD}" \
      --from-literal=email="${GITEA_ADMIN_EMAIL}"
  fi

  helm repo add gitea-charts https://dl.gitea.com/charts/ >/dev/null
  helm repo update >/dev/null
  helm upgrade --install gitea gitea-charts/gitea \
    -n gitea \
    -f "${SCRIPT_DIR}/confs/gitea-values.yaml" \
    --timeout 10m

  echo "[INFO] Waiting for Gitea to be ready..."
  kubectl rollout status deployment/gitea -n gitea --timeout=600s
}

bootstrap_gitea_repo() {
  echo "[INFO] Waiting for Gitea HTTP endpoint..."
  until curl -fsS "${GITEA_URL}/api/v1/version" >/dev/null 2>&1; do
    echo "   still waiting for ${GITEA_URL}..."
    sleep 5
  done

  echo "[INFO] Creating Gitea project..."
  HTTP_CODE="$(curl -s -o /tmp/gitea-repo.json -w '%{http_code}' \
    -u "${GITEA_ADMIN_USER}:${GITEA_ADMIN_PASSWORD}" \
    -X POST "${GITEA_URL}/api/v1/user/repos" \
    -H 'Content-Type: application/json' \
    -d '{"name":"playground","auto_init":false,"private":false,"default_branch":"main"}')"

  if [ "${HTTP_CODE}" != "201" ] && [ "${HTTP_CODE}" != "409" ]; then
    echo "[ERROR] Failed to create repo (HTTP ${HTTP_CODE}):"
    cat /tmp/gitea-repo.json
    exit 1
  fi

  echo "[INFO] Pushing playground manifest to local Gitea..."
  rm -rf "${WORKDIR}"
  mkdir -p "${WORKDIR}"
  cp "${SCRIPT_DIR}/confs/deployment.yaml" "${WORKDIR}/deployment.yaml"

  git -C "${WORKDIR}" init -b main >/dev/null
  git -C "${WORKDIR}" config user.email "${GITEA_ADMIN_EMAIL}"
  git -C "${WORKDIR}" config user.name "IoT Bonus"
  git -C "${WORKDIR}" add deployment.yaml
  git -C "${WORKDIR}" commit -m "Add playground deployment" >/dev/null
  git -C "${WORKDIR}" remote add origin \
    "http://${GITEA_ADMIN_USER}:${GITEA_ADMIN_PASSWORD}@${GITEA_HOST}:8081/${GITEA_ADMIN_USER}/playground.git"
  git -C "${WORKDIR}" push -u origin main --force
}

install_argocd_application() {
  echo "[INFO] Applying Argo CD Application that syncs from local Gitea..."
  kubectl apply -f "${SCRIPT_DIR}/confs/application-gitea.yaml"
}

print_status() {
  echo ""
  echo "[INFO] Bonus setup complete!"
  echo "[INFO] Gitea URL: ${GITEA_URL}"
  echo "[INFO] Gitea username: ${GITEA_ADMIN_USER}"
  echo "[INFO] Gitea password: ${GITEA_ADMIN_PASSWORD}"
  echo ""
  kubectl get ns
  echo ""
  kubectl get application -n argocd
  echo ""
  kubectl get pods -n gitea
  echo ""
  kubectl get pods -n dev
}

install_docker
install_kubectl
install_k3d
install_helm
create_cluster
ensure_hosts_entry
install_argocd
install_gitea
bootstrap_gitea_repo
install_argocd_application
print_status
