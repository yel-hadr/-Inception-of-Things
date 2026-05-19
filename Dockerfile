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

RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" \
    | tar -xz -C /usr/local/bin --strip-components=1 docker/docker \
    && chmod +x /usr/local/bin/docker

RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64" \
    -o /usr/local/bin/k3d \
    && chmod +x /usr/local/bin/k3d

RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
    | tar -xz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/linux-amd64

WORKDIR /workspace

CMD ["bash"]
