# Part 1 - K3s and Vagrant

## Goal

Part 1 creates two Debian 12 Vagrant virtual machines and installs K3s as a small
two-node Kubernetes cluster:

- `yelhadrS`: K3s server/controller node at `192.168.56.110`.
- `yelhadrSW`: K3s agent/worker node at `192.168.56.111`.

This matches the subject requirement for one server machine and one
server-worker machine, both reachable through passwordless Vagrant SSH.

## Files

```text
p1/
+-- Vagrantfile
+-- scripts/
    +-- setup_server.sh
    +-- setup_worker.sh
```

- `Vagrantfile` defines both VMs, hostnames, private IP addresses, and
  VirtualBox resources.
- `scripts/setup_server.sh` installs K3s in server mode on `yelhadrS`.
- `scripts/setup_worker.sh` installs K3s in agent mode on `yelhadrSW` and joins
  it to the server with the shared K3s token.

## How To Run

From this folder:

```bash
cd p1
vagrant up
```

Connect to the server:

```bash
vagrant ssh yelhadrS
```

Check the Kubernetes nodes:

```bash
sudo kubectl get nodes -o wide
```

Expected result:

- `yelhadrS` is `Ready` as the control-plane/server node.
- `yelhadrSW` is `Ready` as the worker/agent node.
- The server node uses `192.168.56.110`.
- The worker node uses `192.168.56.111`.

## Useful Checks

```bash
vagrant status
vagrant ssh yelhadrS -c "ip a"
vagrant ssh yelhadrSW -c "ip a"
vagrant ssh yelhadrS -c "sudo kubectl get nodes -o wide"
```

## Cleanup

```bash
vagrant destroy -f
```

## Notes

The scripts use `eth1` as the private-network interface for K3s flannel. If a
different Linux image exposes the host-only interface with another name, update
the `--flannel-iface` value in both setup scripts.
