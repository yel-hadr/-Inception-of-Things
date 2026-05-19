SHELL := /bin/sh

.PHONY: help \
	p1 p2 p3 bonus \
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

p3: clean-bonus
	docker compose run --rm p3

bonus: clean-p3
	docker compose run --rm bonus

check: check-files

check-files:
	@test -f p1/Vagrantfile
	@test -f p2/Vagrantfile
	@test ! -f p3/Vagrantfile
	@test ! -f bonus/Vagrantfile
	@test -f p3/scripts/setup.sh
	@test -f bonus/scripts/setup.sh
	@test -f docker-compose.yml
	@test -f Dockerfile
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
	docker compose run --rm p3 k3d cluster delete iotcluster || true

clean-bonus:
	docker compose run --rm bonus k3d cluster delete iotbonus || true

status: status-p1 status-p2 status-k3d

status-p1:
	cd p1 && vagrant status

status-p2:
	cd p2 && vagrant status

status-k3d:
	docker compose run --rm p3 k3d cluster list
