RELEASE := jc-consul
NAMESPACE := consul

DEV_CLUSTER ?= testrc
DEV_PROJECT ?= jendevops1
DEV_ZONE ?= australia-southeast1-c

.DEFAULT_TARGET: status

SHELL := /bin/bash

CHART_VERSION ?= v0.9.0

CONSUL_NAMESPACE ?= consul

.DEFAULT_GOAL := src

lint: lint-yaml lint-ci

lint-yaml:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

lint-ci:
	@circleci config validate

.PHONY: clean
clean:
	rm -fr src

src:
	mkdir -p src
	curl -L https://github.com/hashicorp/consul-helm/archive/$(CHART_VERSION).tar.gz | tar zx -C src --strip-components 1

.PHONY: namespace
namespace:
	kubectl get ns $(NAMESPACE) || kubectl create ns $(NAMESPACE)

.PHONY: dev
dev: src helm-install-dev

.PHONY: prod
prod: src namespace helm-install-prod

.PHONY: helm-install-dev
helm-install-dev:
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	helm upgrade --install --force --wait jc-consul \
	--namespace=$(CONSUL_NAMESPACE) \
	-f values.yaml \
	src

