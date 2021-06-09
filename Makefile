SHELL := /bin/bash

RELEASE ?= jc-consul
NAMESPACE ?= consul

CHART_VERSION ?= 0.18.0
CHART_NAME := hashicorp/consul

DEV_CLUSTER ?= testrc
DEV_PROJECT ?= jendevops1
DEV_ZONE ?= australia-southeast1-c

.DEFAULT_GOAL := src

.PHONY: clean
clean:
	rm -fr src

lint: lint-yaml lint-ci

lint-yaml:
		@find . -type f -name '*.yml' | xargs yamllint
		@find . -type f -name '*.yaml' | xargs yamllint

lint-ci:
		@circleci config validate

src:
	mkdir -p src
	curl -L https://github.com/hashicorp/consul-helm/archive/$(CHART_VERSION).tar.gz | tar zx -C src --strip-components 1

init-helm:
	helm init --client-only
	helm repo add hashicorp https://helm.releases.hashicorp.com
	helm repo update

.PHONY: dev
dev: lint init-helm helm-install-dev

.PHONY: prod
prod: lint init-helm helm-install-prod

.PHONY: helm-install-dev
helm-install-dev:
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	-kubectl create namespace $(NAMESPACE)
	helm upgrade --install --force --wait $(RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		-f env/development/values.yaml \
		$(CHART_NAME)
	$(MAKE) history


.PHONY: helm-install-prod
helm-install-prod:
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(PROD_PROJECT)
	gcloud container clusters get-credentials $(PROD_PROJECT) --zone $(PROD_ZONE) --project $(PROD_PROJECT)
	-kubectl create namespace $(NAMESPACE)
	helm upgrade --install --force --wait $(RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		-f env/development/values.yaml \
		$(CHART_NAME)
	$(MAKE) history

history:
	helm history jc-consul --max=5
