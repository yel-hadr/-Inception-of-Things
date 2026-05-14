# Part 2 - K3s and Three Applications

## Goal

Part 2 creates one Debian 12 Vagrant virtual machine named `yelhadrS` at
`192.168.56.110`, installs K3s in server mode, and deploys three web
applications.

The applications are exposed through Traefik Ingress:

- `app1.com` routes to `app1`.
- `app2.com` routes to `app2`.
- Any other host routes to `app3` by default.

The subject requires application 2 to have three replicas, which is configured in
`confs/app2.yaml`.

## Files

```text
p2/
+-- Vagrantfile
+-- confs/
|   +-- app1.yaml
|   +-- app2.yaml
|   +-- app3.yaml
|   +-- ingress.yaml
+-- scripts/
    +-- setup_server.sh
```

- `Vagrantfile` creates the single VM with IP `192.168.56.110`.
- `scripts/setup_server.sh` installs K3s, configures kubectl for the `vagrant`
  user, waits for the node, and applies all manifests from `/vagrant/confs`.
- `confs/app1.yaml`, `confs/app2.yaml`, and `confs/app3.yaml` define the
  deployments and services.
- `confs/ingress.yaml` defines host-based routing through Traefik.

## How To Run

From this folder:

```bash
cd p2
vagrant up
```

Connect to the VM:

```bash
vagrant ssh yelhadrS
```

Check the cluster:

```bash
kubectl get nodes -o wide
kubectl get pods -o wide
kubectl get svc
kubectl get ingress
```

## Test The Ingress

From the host machine:

```bash
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl -H "Host: anything.local" http://192.168.56.110
```

Expected routing:

- The first command reaches `app1-svc`.
- The second command reaches `app2-svc`.
- The third command reaches `app3-svc`, because it is the default rule.

Check that `app2` has three replicas:

```bash
kubectl get deployment app2
kubectl get pods -l app=app2
```

## Cleanup

```bash
vagrant destroy -f
```
