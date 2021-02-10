RELEASE := consul
NAMESPACE := consul

CHART_NAME := hashicorp/consul
CHART_VERSION ?= 0.12.0

DEV_CLUSTER ?= testrc
DEV_PROJECT ?= jendevops1
DEV_ZONE ?= australia-southeast1-c

.DEFAULT_TARGET: status

lint:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

init:
	helm3 repo add hashicorp https://helm.releases.hashicorp.com
	helm3 repo update

dev: lint init
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	helm3 upgrade --install --wait $(RELEASE) \
		--set grafana.adminPassword=$(DEV_GRAFANA_PW) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		$(CHART_NAME)
	$(MAKE) history

destroy:
	helm3 uninstall $(RELEASE) -n $(NAMESPACE)

history:
	helm3 history $(RELEASE) -n $(NAMESPACE) --max=5
