# PoC: verify broker authorization via Kubernetes SubjectAccessReview.
# Creates kind clusters with different authorization modes and runs the
# same scenarios against each, so you can see the authorizer-agnostic
# behavior for yourself.

SHELL := /usr/bin/env bash
REPO_ABSPATH := $(CURDIR)

# Cluster names.
RBAC_CLUSTER         := spire-broker-rbac
ABAC_CLUSTER         := spire-broker-abac
ALWAYSALLOW_CLUSTER  := spire-broker-alwaysallow

.PHONY: all rbac abac alwaysallow clean build kind-abac-config

all: rbac abac alwaysallow

build: check

check: main.go go.mod go.sum
	CGO_ENABLED=0 go build -o check .

# Generate the ABAC kind config with the absolute repo path for the bind mount.
kind-abac.yaml: kind-abac.yaml.tpl
	sed 's|__REPO_ABSPATH__|$(REPO_ABSPATH)|g' $< > $@

rbac: check
	@echo "=== Creating RBAC cluster ($(RBAC_CLUSTER)) ==="
	kind create cluster --name $(RBAC_CLUSTER)
	kubectl --context kind-$(RBAC_CLUSTER) apply -f manifests.yaml || true
	sleep 3
	kubectl --context kind-$(RBAC_CLUSTER) apply -f manifests.yaml
	@echo
	kubectl config use-context kind-$(RBAC_CLUSTER)
	./run-scenarios.sh

abac: check kind-abac.yaml
	@echo "=== Creating ABAC cluster ($(ABAC_CLUSTER)) ==="
	kind create cluster --config kind-abac.yaml
	kubectl --context kind-$(ABAC_CLUSTER) apply -f manifests.yaml || true
	sleep 3
	kubectl --context kind-$(ABAC_CLUSTER) apply -f manifests.yaml
	@echo
	kubectl config use-context kind-$(ABAC_CLUSTER)
	./run-scenarios.sh

alwaysallow: check
	@echo "=== Creating AlwaysAllow cluster ($(ALWAYSALLOW_CLUSTER)) ==="
	kind create cluster --config kind-alwaysallow.yaml
	kubectl --context kind-$(ALWAYSALLOW_CLUSTER) apply -f manifests.yaml || true
	sleep 3
	kubectl --context kind-$(ALWAYSALLOW_CLUSTER) apply -f manifests.yaml
	@echo
	kubectl config use-context kind-$(ALWAYSALLOW_CLUSTER)
	./run-scenarios.sh

clean:
	-kind delete cluster --name $(RBAC_CLUSTER)
	-kind delete cluster --name $(ABAC_CLUSTER)
	-kind delete cluster --name $(ALWAYSALLOW_CLUSTER)
	rm -f check kind-abac.yaml
