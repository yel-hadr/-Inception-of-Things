#!/bin/bash
set -e

CLUSTER_NAME="iotbonus"
ROOT_PASSWORD="${GITLAB_ROOT_PASSWORD:-Password42!}"
GITLAB_TOKEN="${GITLAB_TOKEN:-iot-bonus-token-42}"
GITLAB_HOST="gitlab.localhost"
GITLAB_URL="http://${GITLAB_HOST}:8081"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="/tmp/iot-bonus-playground"

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
  if ! grep -q "[[:space:]]${GITLAB_HOST}$" /etc/hosts; then
    echo "[INFO] Adding ${GITLAB_HOST} to /etc/hosts..."
    echo "127.0.0.1 ${GITLAB_HOST}" >> /etc/hosts
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

install_gitlab() {
  echo "[INFO] Installing GitLab CE in namespace gitlab..."
  kubectl get namespace gitlab >/dev/null 2>&1 || kubectl create namespace gitlab

  if ! kubectl get secret gitlab-root-password -n gitlab >/dev/null 2>&1; then
    kubectl create secret generic gitlab-root-password \
      -n gitlab \
      --from-literal=password="${ROOT_PASSWORD}"
  fi

  helm repo add gitlab https://charts.gitlab.io >/dev/null
  helm repo update >/dev/null
  helm upgrade --install gitlab gitlab/gitlab \
    -n gitlab \
    -f "${SCRIPT_DIR}/confs/gitlab-values.yaml" \
    --timeout 20m

  echo "[INFO] Waiting for GitLab webservice. This can take 10-20 minutes..."
  kubectl rollout status deployment/gitlab-webservice-default -n gitlab --timeout=1200s
  kubectl rollout status deployment/gitlab-sidekiq-all-in-1-v2 -n gitlab --timeout=1200s || true
  kubectl rollout status deployment/gitlab-toolbox -n gitlab --timeout=1200s || true
}

bootstrap_gitlab_repo() {
  echo "[INFO] Waiting for GitLab HTTP endpoint..."
  until curl -fsS "${GITLAB_URL}/users/sign_in" >/dev/null 2>&1; do
    echo "   still waiting for ${GITLAB_URL}..."
    sleep 10
  done

  echo "[INFO] Creating GitLab project and access token..."
  TOOLBOX_POD="$(kubectl get pod -n gitlab -l app=toolbox -o jsonpath='{.items[0].metadata.name}')"

  kubectl exec -n gitlab "${TOOLBOX_POD}" -- gitlab-rails runner "
root = User.find_by_username('root')
project = Project.find_by_full_path('root/playground')
unless project
  project = Projects::CreateService.new(root, {
    name: 'playground',
    path: 'playground',
    namespace_id: root.namespace.id,
    visibility_level: Gitlab::VisibilityLevel::PUBLIC
  }).execute
end
token = root.personal_access_tokens.find_by_name('iot-bonus-token')
unless token
  token = root.personal_access_tokens.create!(
    name: 'iot-bonus-token',
    scopes: [:api, :read_repository, :write_repository],
    expires_at: 1.year.from_now
  )
  token.set_token('${GITLAB_TOKEN}')
  token.save!
end
puts project.web_url
"

  echo "[INFO] Pushing playground manifest to local GitLab..."
  rm -rf "${WORKDIR}"
  mkdir -p "${WORKDIR}"
  cp "${SCRIPT_DIR}/confs/deployment.yaml" "${WORKDIR}/deployment.yaml"

  git -C "${WORKDIR}" init -b main >/dev/null
  git -C "${WORKDIR}" config user.email "iot@example.local"
  git -C "${WORKDIR}" config user.name "IoT Bonus"
  git -C "${WORKDIR}" add deployment.yaml
  git -C "${WORKDIR}" commit -m "Add playground deployment" >/dev/null
  git -C "${WORKDIR}" remote add origin "http://root:${GITLAB_TOKEN}@${GITLAB_HOST}:8081/root/playground.git"
  git -C "${WORKDIR}" push -u origin main --force
}

install_argocd_application() {
  echo "[INFO] Applying Argo CD Application that syncs from local GitLab..."
  kubectl apply -f "${SCRIPT_DIR}/confs/application-gitlab.yaml"
}

print_status() {
  echo ""
  echo "[INFO] Bonus setup complete!"
  echo "[INFO] GitLab URL: ${GITLAB_URL}"
  echo "[INFO] GitLab username: root"
  echo "[INFO] GitLab password: ${ROOT_PASSWORD}"
  echo ""
  kubectl get ns
  echo ""
  kubectl get application -n argocd
  echo ""
  kubectl get pods -n gitlab
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
install_gitlab
bootstrap_gitlab_repo
install_argocd_application
print_status
