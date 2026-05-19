# Inception of Things

This repository contains the four parts of the 42 `Inception-of-Things` project.
The subject asks for all mandatory work to be split at the repository root into
`p1`, `p2`, and `p3`, with the optional local Gitea GitOps work in `bonus`.

## Subject Summary

- `p1`: create two Vagrant virtual machines and install K3s in server/agent mode.
- `p2`: create one Vagrant virtual machine, install K3s in server mode, and expose
  three web applications through Ingress using host-based routing.
- `p3`: use K3d instead of Vagrant, install Argo CD, and let Argo CD deploy a
  versioned application from a public Git repository.
- `bonus`: add a local Gitea instance and make the Part 3 GitOps flow work from
  that local Gitea repository. Gitea is used instead of GitLab because it is much
  lighter for laptop-sized environments.

## Repository Layout

```text
.
+-- p1/
|   +-- Vagrantfile
|   +-- scripts/
+-- p2/
|   +-- Vagrantfile
|   +-- confs/
|   +-- scripts/
+-- p3/
|   +-- confs/
|   +-- deployment.yaml
|   +-- scripts/
+-- bonus/
    +-- confs/
    +-- scripts/
```

Each part has its own README with the goal, important files, launch commands, and
defense checks.

## Requirements

Run the project from a Linux VM or a compatible WSL/Linux environment with the
tools required by each part:

- Vagrant and VirtualBox for `p1` and `p2`.
- Docker, kubectl, and K3d for `p3` and `bonus`.
- Helm for `bonus`.

The setup scripts install several tools automatically when they are missing.

## Docker Runner for P3 and Bonus

If you already have Docker available on a Linux VM, you can run the K3d/Argo CD
parts through the provided Docker image instead of installing kubectl, K3d, and
Helm directly on the VM. The container uses the host Docker socket so K3d can
create Kubernetes nodes as Docker containers.

```bash
docker compose run --rm p3
docker compose run --rm bonus
```

The compose file exposes the same ports as the scripts:

- `http://localhost:8888` for the playground app.
- `http://gitea.localhost:8081` for the bonus Gitea UI.

## Evaluation Order

The subject expects the mandatory parts to be evaluated in this order:

1. `p1`
2. `p2`
3. `p3`

The `bonus` folder is evaluated only after all mandatory parts are working.
