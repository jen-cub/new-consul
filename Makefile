SHELL := /bin/bash

CHART_VERSION ?= v0.7.0

CONSUL_NAMESPACE ?= consul

.DEFAULT_GOAL := src

.PHONY: clean
clean:
	rm -fr src

src:
	mkdir -p src
	curl -L https://github.com/hashicorp/consul-helm/archive/$(CHART_VERSION).tar.gz | tar zx -C src --strip-components 1

.PHONY: namespace
namespace:
	kubectl get ns $(CONSUL_NAMESPACE) || kubectl create ns $(CONSUL_NAMESPACE)

.PHONY: dev
dev: src namespace helm-install-dev

.PHONY: prod
prod: src namespace helm-install-prod

.PHONY: helm-install-dev
helm-install-dev:
	helm upgrade --install --force --wait p4-consul \
	--namespace=$(CONSUL_NAMESPACE) \
	-f values.yaml \
	-f env/development/values.yaml \
	src

.PHONY: helm-install-prod
helm-install-prod:
	helm upgrade --install --force --wait p4-consul \
	--namespace=$(CONSUL_NAMESPACE) \
	-f values.yaml \
	-f env/production/values.yaml \
	src
