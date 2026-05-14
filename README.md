# Inception of Things

This repository contains the four parts of the 42 `Inception-of-Things` project.
The subject asks for all mandatory work to be split at the repository root into
`p1`, `p2`, and `p3`, with the optional GitLab work in `bonus`.

## Subject Summary

- `p1`: create two Vagrant virtual machines and install K3s in server/agent mode.
- `p2`: create one Vagrant virtual machine, install K3s in server mode, and expose
  three web applications through Ingress using host-based routing.
- `p3`: use K3d instead of Vagrant, install Argo CD, and let Argo CD deploy a
  versioned application from a public Git repository.
- `bonus`: add a local GitLab instance and make the Part 3 GitOps flow work from
  that local GitLab repository.

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

## Evaluation Order

The subject expects the mandatory parts to be evaluated in this order:

1. `p1`
2. `p2`
3. `p3`

The `bonus` folder is evaluated only after all mandatory parts are working.
