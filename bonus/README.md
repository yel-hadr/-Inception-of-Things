# Bonus - Local Gitea GitOps

## Goal

The bonus adds a local Gitea instance to the Part 3 GitOps setup. It creates a
dedicated K3d cluster, installs Gitea in a `gitea` namespace, creates a local
Gitea project, pushes the playground manifest into that project, and configures
Argo CD to sync from Gitea instead of GitHub.

Gitea is intentionally used instead of GitLab here because GitLab is too heavy
for many laptops and lab VMs. The GitOps behavior remains the same: Argo CD
watches a Git repository and reconciles the `dev` namespace from it.

The subject requires:

- A local Gitea instance.
- A dedicated `gitea` namespace.
- Gitea connected to the cluster.
- The Part 3 Argo CD workflow working from the local Gitea repository.

## Files

```text
bonus/
+-- confs/
|   +-- application-gitea.yaml
|   +-- deployment.yaml
|   +-- gitea-values.yaml
+-- scripts/
    +-- setup.sh
```

- `scripts/setup.sh` installs Docker, kubectl, K3d, and Helm when missing, creates
  the `iotbonus` cluster, installs Argo CD, installs Gitea, bootstraps a
  `gitea_admin/playground` project, and applies the Argo CD Application.
- `confs/gitea-values.yaml` configures the Gitea Helm chart for local HTTP use
  (SQLite, in-memory cache, Traefik ingress).
- `confs/deployment.yaml` contains the initial `wil42/playground:v1` deployment.
- `confs/application-gitea.yaml` points Argo CD to the in-cluster Gitea service.

## How To Run

Run from the repository root inside your VM, WSL, or Linux environment:

```bash
sudo bash bonus/scripts/setup.sh
```

Gitea is light. The first install usually finishes in a couple of minutes.

The script creates a K3d cluster named `iotbonus` and exposes:

```text
http://localhost:8888          playground application
http://gitea.localhost:8081    Gitea UI
```

The script also adds this hosts entry when missing:

```text
127.0.0.1 gitea.localhost
```

## Run With Docker

From the repository root, you can also run the bonus through the shared Docker
runner:

```bash
docker compose run --rm bonus
```

The runner mounts `/var/run/docker.sock` from the host VM, so Docker must already
be installed and running on that VM.

## Gitea Credentials

Default credentials used by the script:

```text
username: gitea_admin
password: Password42!
```

You can override the admin password before running the script:

```bash
export GITEA_ADMIN_PASSWORD="your-password"
sudo -E bash bonus/scripts/setup.sh
```

## Useful Checks

```bash
kubectl get ns
kubectl get application -n argocd
kubectl get pods -n gitea
kubectl get pods -n dev
curl http://localhost:8888/
```

Expected initial application response:

```json
{"status":"ok", "message": "v1"}
```

## Demonstrate GitOps From Gitea

Open Gitea:

```text
http://gitea.localhost:8081
```

Edit the image tag in the `gitea_admin/playground` repository:

```yaml
image: wil42/playground:v1
```

Change it to:

```yaml
image: wil42/playground:v2
```

Commit the change and wait for Argo CD to sync. You can force a refresh with:

```bash
kubectl annotate application playground-gitea -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
```

Expected final test:

```bash
curl http://localhost:8888/
```

```json
{"status":"ok", "message": "v2"}
```

## Cleanup

```bash
k3d cluster delete iotbonus
```
