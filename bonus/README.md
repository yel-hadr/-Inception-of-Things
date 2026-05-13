# Bonus - Local GitLab GitOps

This bonus creates a dedicated K3d cluster, installs GitLab CE in a namespace named `gitlab`, and configures Argo CD to sync the playground app from the local GitLab repository.

Run from the repository root inside your VM/WSL environment:

```bash
sudo bash bonus/scripts/setup.sh
```

GitLab is heavy. The first install can take 10-20 minutes and needs several GB of RAM.

After setup:

```bash
kubectl get ns
kubectl get application -n argocd
kubectl get pods -n gitlab
kubectl get pods -n dev
curl http://localhost:8888/
```

GitLab UI:

```text
http://gitlab.localhost:8081
```

Default credentials used by the script:

```text
username: root
password: Password42!
```

To prove GitOps, edit the image tag in the GitLab `root/playground` repository from `wil42/playground:v1` to `wil42/playground:v2`, then wait for Argo CD to sync. You can force a refresh with:

```bash
kubectl annotate application playground-gitlab -n argocd argocd.argoproj.io/refresh=hard --overwrite
```

Expected final test:

```bash
curl http://localhost:8888/
```

```json
{"status":"ok", "message": "v2"}
```
