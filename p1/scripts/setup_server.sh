#!/bin/bash
# On the server VM

curl -sfL https://get.k3s.io | K3S_TOKEN="UM3uyHxtV7Q5FamR06d4rgX3dP9fwuGZ2Ec3RsqsRW35La52Aro5gRyiQoSvbkc20aBI68uZfA6BC5BBMUoTPeGSAWrlKtoocjXp8hYBxiM6Dpmyw2BOLakpWPQ3xIwWZmLo1zF1eMTWjqHF3oF" sh -s - server \
    --flannel-iface=eth1 \
    --node-ip=192.168.56.110


until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
    sleep 2
done
echo "Server ready"