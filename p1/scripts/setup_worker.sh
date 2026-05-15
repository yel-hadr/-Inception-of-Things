#!/bin/bash
set -euo pipefail

readonly K3S_SERVER_URL="https://192.168.56.110:6443"
readonly K3S_TOKEN="UM3uyHxtV7Q5FamR06d4rgX3dP9fwuGZ2Ec3RsqsRW35La52Aro5gRyiQoSvbkc20aBI68uZfA6BC5BBMUoTPeGSAWrlKtoocjXp8hYBxiM6Dpmyw2BOLakpWPQ3xIwWZmLo1zF1eMTWjqHF3oF"
readonly NODE_IP="192.168.56.111"
readonly FLANNEL_IFACE="eth1"
export K3S_TOKEN K3S_URL="${K3S_SERVER_URL}"

echo "Waiting for K3s server API at ${K3S_SERVER_URL}..."
until curl -skf "${K3S_SERVER_URL}/readyz" >/dev/null; do
    sleep 3
done

if systemctl is-active --quiet k3s-agent; then
    echo "K3s agent is already running"
else
    curl -sfL https://get.k3s.io | sh -s - agent \
        --flannel-iface="${FLANNEL_IFACE}" \
        --node-ip="${NODE_IP}"
fi

echo "Worker joined the cluster"
