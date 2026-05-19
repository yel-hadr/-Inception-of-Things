.PHONY: help \
	p1 p2 p3 bonus \
	docker-files docker-build \
	check check-files check-p1 check-p2 check-p3 check-bonus \
	verify verify-p1 verify-p2 verify-p3 verify-bonus \
	clean clean-p1 clean-p2 clean-p3 clean-bonus \
	status status-p1 status-p2 status-k3d

.DEFAULT_GOAL := help

help:
	@echo "Inception-of-Things targets"
	@echo ""
	@echo "Run:"
	@echo "  make p1            Start Part 1 Vagrant cluster"
	@echo "  make p2            Start Part 2 Vagrant cluster"
	@echo "  make p3            Start Part 3 K3d/Argo CD flow"
	@echo "  make bonus         Start bonus K3d/Gitea/Argo CD flow"
	@echo "  make docker-files  Generate Dockerfile, .dockerignore, and docker-compose.yml"
	@echo "  make docker-build  Generate Docker files and build the runner image"
	@echo ""
	@echo "Check:"
	@echo "  make check-p1      Check Part 1 nodes"
	@echo "  make check-p2      Check Part 2 apps and ingress"
	@echo "  make check-p3      Check Part 3 Argo CD app and curl localhost:8888"
	@echo "  make check-bonus   Check bonus Gitea, Argo CD app, and curl endpoints"
	@echo "  make check         Run file/static checks"
	@echo "  make verify-p3     Run P3, then check P3"
	@echo "  make verify-bonus  Run bonus, then check bonus"
	@echo "  make verify        Run every part with checks; this can take a while"
	@echo ""
	@echo "Clean:"
	@echo "  make clean-p1      Destroy Part 1 Vagrant machines"
	@echo "  make clean-p2      Destroy Part 2 Vagrant machine"
	@echo "  make clean-p3      Delete Part 3 K3d cluster"
	@echo "  make clean-bonus   Delete bonus K3d cluster"
	@echo "  make clean         Clean all parts"
	@echo ""
	@echo "Status:"
	@echo "  make status        Show Vagrant and K3d status"

p1:
	cd p1 && vagrant up

p2:
	cd p2 && vagrant up

p3: docker-files clean-bonus
	docker compose run --rm p3

bonus: docker-files clean-p3
	docker compose run --rm bonus

docker-files:
	$(file >Dockerfile,$(DOCKERFILE_CONTENT))
	$(file >.dockerignore,$(DOCKERIGNORE_CONTENT))
	$(file >docker-compose.yml,$(DOCKER_COMPOSE_CONTENT))
	@echo "Generated Dockerfile, .dockerignore, and docker-compose.yml."

docker-build: docker-files
	docker compose build

check: check-files

check-files:
	$(if $(wildcard p1/Vagrantfile),,$(error Missing p1/Vagrantfile))
	$(if $(wildcard p2/Vagrantfile),,$(error Missing p2/Vagrantfile))
	$(if $(wildcard p3/Vagrantfile),$(error p3/Vagrantfile should not exist),)
	$(if $(wildcard bonus/Vagrantfile),$(error bonus/Vagrantfile should not exist),)
	$(if $(wildcard p3/scripts/setup.sh),,$(error Missing p3/scripts/setup.sh))
	$(if $(wildcard bonus/scripts/setup.sh),,$(error Missing bonus/scripts/setup.sh))
	$(if $(wildcard docker-compose.yml),,$(error Missing docker-compose.yml))
	$(if $(wildcard Dockerfile),,$(error Missing Dockerfile))
	@echo "File layout checks passed."

check-p1:
	cd p1 && vagrant status
	cd p1 && vagrant ssh yelhadrS -c "sudo kubectl get nodes -o wide"

check-p2:
	cd p2 && vagrant status
	cd p2 && vagrant ssh yelhadrS -c "kubectl get nodes -o wide"
	cd p2 && vagrant ssh yelhadrS -c "kubectl get pods -o wide"
	cd p2 && vagrant ssh yelhadrS -c "kubectl get deployment app2"
	curl -H "Host: app1.com" http://192.168.56.110
	curl -H "Host: app2.com" http://192.168.56.110
	curl -H "Host: anything.local" http://192.168.56.110

check-p3:
	docker compose run --rm p3 kubectl wait --for=condition=available deployment/playground -n dev --timeout=300s
	docker compose run --rm p3 kubectl get application playground -n argocd
	docker compose run --rm p3 kubectl get pods -n dev -o wide
	curl http://localhost:8888/

check-bonus:
	docker compose run --rm bonus kubectl wait --for=condition=available deployment/gitea -n gitea --timeout=300s
	docker compose run --rm bonus kubectl wait --for=condition=available deployment/playground -n dev --timeout=300s
	docker compose run --rm bonus kubectl get application playground-gitea -n argocd
	docker compose run --rm bonus kubectl get pods -n gitea
	docker compose run --rm bonus kubectl get pods -n dev -o wide
	curl -I http://gitea.localhost:8081/
	curl http://localhost:8888/

verify: verify-p1 clean-p1 verify-p2 clean-p2 verify-p3 clean-p3 verify-bonus

verify-p1: p1 check-p1

verify-p2: p2 check-p2

verify-p3: p3 check-p3

verify-bonus: bonus check-bonus

clean: clean-p1 clean-p2 clean-p3 clean-bonus

clean-p1:
	cd p1 && vagrant destroy -f

clean-p2:
	cd p2 && vagrant destroy -f

clean-p3:
	-docker compose run --rm p3 k3d cluster delete iotcluster

clean-bonus:
	-docker compose run --rm bonus k3d cluster delete iotbonus

status: status-p1 status-p2 status-k3d

status-p1:
	cd p1 && vagrant status

status-p2:
	cd p2 && vagrant status

status-k3d:
	docker compose run --rm p3 k3d cluster list

define DOCKERFILE_CONTENT
FROM debian:bookworm-slim

ARG K3D_VERSION=v5.8.3
ARG KUBECTL_VERSION=v1.30.14
ARG HELM_VERSION=v3.18.6
ARG DOCKER_CLI_VERSION=27.5.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      gnupg \
      iproute2 \
      iptables \
      procps \
      uidmap \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-$${DOCKER_CLI_VERSION}.tgz" \
    | tar -xz -C /usr/local/bin --strip-components=1 docker/docker \
    && chmod +x /usr/local/bin/docker

RUN curl -fsSL "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://github.com/k3d-io/k3d/releases/download/$${K3D_VERSION}/k3d-linux-amd64" \
    -o /usr/local/bin/k3d \
    && chmod +x /usr/local/bin/k3d

RUN curl -fsSL "https://get.helm.sh/helm-$${HELM_VERSION}-linux-amd64.tar.gz" \
    | tar -xz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/linux-amd64

WORKDIR /workspace

CMD ["bash"]
endef

define DOCKERIGNORE_CONTENT
.git
.venv
.qodo
**/.vagrant
endef

define DOCKER_COMPOSE_CONTENT
services:
  p3:
    build: .
    image: iot-k3d-runner:latest
    network_mode: host
    privileged: true
    working_dir: /workspace
    volumes:
      - .:/workspace
      - /var/run/docker.sock:/var/run/docker.sock
      - iot-kube:/root/.kube
      - iot-k3d:/root/.config/k3d
    command: ["bash", "p3/scripts/setup.sh"]

  bonus:
    build: .
    image: iot-k3d-runner:latest
    network_mode: host
    privileged: true
    working_dir: /workspace
    environment:
      GITEA_ADMIN_USER: $${GITEA_ADMIN_USER:-gitea_admin}
      GITEA_ADMIN_PASSWORD: $${GITEA_ADMIN_PASSWORD:-Password42!}
      GITEA_ADMIN_EMAIL: $${GITEA_ADMIN_EMAIL:-admin@gitea.local}
    volumes:
      - .:/workspace
      - /var/run/docker.sock:/var/run/docker.sock
      - iot-kube:/root/.kube
      - iot-k3d:/root/.config/k3d
    command: ["bash", "bonus/scripts/setup.sh"]

volumes:
  iot-kube:
  iot-k3d:
endef
