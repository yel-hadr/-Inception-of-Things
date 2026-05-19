.PHONY: help \
	p1 p2 p3 bonus \
	refresh-p3 refresh-bonus argocd-ui argocd-password \
	check check-files check-subject check-p1 check-p2 check-p3 check-bonus \
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
	@echo "  make refresh-p3    Force Argo CD refresh for P3 playground"
	@echo "  make refresh-bonus Force Argo CD refresh for bonus playground-gitea"
	@echo "  make argocd-ui     Forward Argo CD UI to https://localhost:8080"
	@echo "  make argocd-password"
	@echo "                     Print Argo CD initial admin password"
	@echo ""
	@echo "Check:"
	@echo "  make check-p1      Check Part 1 nodes"
	@echo "  make check-p2      Check Part 2 apps and ingress"
	@echo "  make check-p3      Check Part 3 Argo CD app and curl localhost:8888"
	@echo "  make check-bonus   Check bonus Gitea, Argo CD app, and curl endpoints"
	@echo "  make check         Run subject and file/static checks"
	@echo "  make check-subject Check static layout against en.subject.pdf"
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
	sudo bash p3/scripts/setup.sh

bonus: clean-p3
	sudo bash bonus/scripts/setup.sh

refresh-p3:
	kubectl annotate application playground -n argocd argocd.argoproj.io/refresh=hard --overwrite

refresh-bonus:
	kubectl annotate application playground-gitea -n argocd argocd.argoproj.io/refresh=hard --overwrite

argocd-ui:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argocd-password:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

check: check-files check-subject

check-files:
	$(if $(wildcard p1/Vagrantfile),,$(error Missing p1/Vagrantfile))
	$(if $(wildcard p2/Vagrantfile),,$(error Missing p2/Vagrantfile))
	$(if $(wildcard p3/Vagrantfile),$(error p3/Vagrantfile should not exist),)
	$(if $(wildcard bonus/Vagrantfile),$(error bonus/Vagrantfile should not exist),)
	$(if $(wildcard p3/scripts/setup.sh),,$(error Missing p3/scripts/setup.sh))
	$(if $(wildcard bonus/scripts/setup.sh),,$(error Missing bonus/scripts/setup.sh))
	$(if $(wildcard Makefile),,$(error Missing Makefile))
	$(if $(wildcard en.subject.pdf),,$(error Missing en.subject.pdf))
	@echo "File layout checks passed."

check-subject:
	$(if $(wildcard p1/scripts),,$(error Subject check: missing p1/scripts))
	$(if $(wildcard p1/confs),,$(warning Subject note: p1/confs is listed in the subject example but is not used by this implementation))
	$(if $(wildcard p2/scripts),,$(error Subject check: missing p2/scripts))
	$(if $(wildcard p2/confs),,$(error Subject check: missing p2/confs))
	$(if $(wildcard p3/scripts),,$(error Subject check: missing p3/scripts))
	$(if $(wildcard p3/confs),,$(error Subject check: missing p3/confs))
	$(if $(wildcard bonus/scripts),,$(error Subject check: missing bonus/scripts))
	$(if $(wildcard bonus/confs),,$(error Subject check: missing bonus/confs))
	@echo "Subject layout checks passed. See SUBJECT_CHECK.md for the full checklist."

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
	kubectl wait --for=condition=available deployment/playground -n dev --timeout=300s
	kubectl get application playground -n argocd
	kubectl get pods -n dev -o wide
	curl http://localhost:8888/

check-bonus:
	kubectl wait --for=condition=available deployment/gitea -n gitea --timeout=300s
	kubectl wait --for=condition=available deployment/playground -n dev --timeout=300s
	kubectl get application playground-gitea -n argocd
	kubectl get pods -n gitea
	kubectl get pods -n dev -o wide
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
	-k3d cluster delete iotcluster

clean-bonus:
	-k3d cluster delete iotbonus

status: status-p1 status-p2 status-k3d

status-p1:
	cd p1 && vagrant status

status-p2:
	cd p2 && vagrant status

status-k3d:
	k3d cluster list
