# Subject Check - Inception of Things

This checklist is based on `en.subject.pdf` and is meant as a quick defense
review before evaluation.

## General

- Whole project should be run inside a virtual machine.
- Mandatory folders at repository root: `p1`, `p2`, `p3`.
- Optional bonus folder at repository root: `bonus`.
- Scripts should live in `scripts/`.
- Configuration files should live in `confs/`.
- Mandatory parts must be completed in order: P1, then P2, then P3.

## Part 1 - K3s and Vagrant

- `p1/Vagrantfile` exists.
- Two VMs are created with Vagrant.
- Server hostname ends with `S`; worker hostname ends with `SW`.
- Server IP: `192.168.56.110`.
- Worker IP: `192.168.56.111`.
- SSH works without password.
- K3s server runs in controller mode.
- K3s worker runs in agent mode.
- `kubectl get nodes -o wide` shows both nodes `Ready`.

## Part 2 - K3s and Three Applications

- `p2/Vagrantfile` exists.
- One VM is created with Vagrant.
- VM hostname ends with `S`.
- VM IP: `192.168.56.110`.
- K3s runs in server mode.
- Three apps are deployed.
- Requests with host `app1.com` reach app1.
- Requests with host `app2.com` reach app2.
- Any other host reaches app3 by default.
- App2 has 3 replicas.

## Part 3 - K3d and Argo CD

- No Vagrant is used for P3.
- Docker and K3d are installed by script.
- Namespace `argocd` exists.
- Namespace `dev` exists.
- Argo CD is installed in `argocd`.
- The app is deployed in `dev`.
- Argo CD syncs from a public GitHub repository.
- The GitHub repository name includes a team member login.
- The app can demonstrate `v1` to `v2` by changing the Git manifest.

## Bonus

- Subject asks for local GitLab in a `gitlab` namespace.
- This implementation intentionally uses local Gitea in a `gitea` namespace
  because GitLab is too heavy for the laptop environment.
- Argo CD still syncs from a self-hosted local Git repository.
- The Part 3 GitOps flow works from that local Git service.

## Commands

```bash
make check
make verify-p3
make verify-bonus
```

P3 and bonus are run directly on the local machine through their setup scripts.
