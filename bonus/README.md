# Bonus - Local GitLab GitOps

## Goal

The bonus adds a local GitLab instance to the Part 3 GitOps setup. It creates a
dedicated K3d cluster, installs GitLab CE in a `gitlab` namespace, creates a local
GitLab project, pushes the playground manifest into that project, and configures
Argo CD to sync from GitLab instead of GitHub.

The subject requires:

- A local GitLab instance.
- A dedicated `gitlab` namespace.
- GitLab connected to the cluster.
- The Part 3 Argo CD workflow working from the local GitLab repository.

## Files

```text
bonus/
+-- confs/
|   +-- application-gitlab.yaml
|   +-- deployment.yaml
|   +-- gitlab-values.yaml
+-- scripts/
    +-- setup.sh
```

- `scripts/setup.sh` installs Docker, kubectl, K3d, and Helm when missing, creates
  the `iotbonus` cluster, installs Argo CD, installs GitLab, bootstraps a
  `root/playground` project, and applies the Argo CD Application.
- `confs/gitlab-values.yaml` configures the GitLab Helm chart for local HTTP use.
- `confs/deployment.yaml` contains the initial `wil42/playground:v1` deployment.
- `confs/application-gitlab.yaml` points Argo CD to the in-cluster GitLab service.

## How To Run

Run from the repository root inside your VM, WSL, or Linux environment:

```bash
sudo bash bonus/scripts/setup.sh
```

GitLab is heavy. The first install can take 10 to 20 minutes and needs several GB
of RAM.

The script creates a K3d cluster named `iotbonus` and exposes:

```text
http://localhost:8888          playground application
http://gitlab.localhost:8081   GitLab UI
```

The script also adds this hosts entry when missing:

```text
127.0.0.1 gitlab.localhost
```

## GitLab Credentials

Default credentials used by the script:

```text
username: root
password: Password42!
```

You can override the root password before running the script:

```bash
export GITLAB_ROOT_PASSWORD="your-password"
sudo -E bash bonus/scripts/setup.sh
```

## Useful Checks

```bash
kubectl get ns
kubectl get application -n argocd
kubectl get pods -n gitlab
kubectl get pods -n dev
curl http://localhost:8888/
```

Expected initial application response:

```json
{"status":"ok", "message": "v1"}
```

## Demonstrate GitOps From GitLab

Open GitLab:

```text
http://gitlab.localhost:8081
```

Edit the image tag in the `root/playground` repository:

```yaml
image: wil42/playground:v1
```

Change it to:

```yaml
image: wil42/playground:v2
```

Commit the change and wait for Argo CD to sync. You can force a refresh with:

```bash
kubectl annotate application playground-gitlab -n argocd \
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
