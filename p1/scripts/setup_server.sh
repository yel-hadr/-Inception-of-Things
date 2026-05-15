#!/bin/bash
set -euo pipefail

readonly K3S_TOKEN="UM3uyHxtV7Q5FamR06d4rgX3dP9fwuGZ2Ec3RsqsRW35La52Aro5gRyiQoSvbkc20aBI68uZfA6BC5BBMUoTPeGSAWrlKtoocjXp8hYBxiM6Dpmyw2BOLakpWPQ3xIwWZmLo1zF1eMTWjqHF3oF"
readonly NODE_IP="192.168.56.110"
readonly FLANNEL_IFACE="eth1"

if systemctl is-active --quiet k3s; then
    echo "K3s server is already running"
else
    curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" sh -s - server \
        --flannel-iface="${FLANNEL_IFACE}" \
        --node-ip="${NODE_IP}"
fi

echo "Waiting for K3s server node to become Ready..."
until sudo kubectl get nodes 2>/dev/null | grep -q " Ready "; do
    sleep 2
done

echo "Server ready"
