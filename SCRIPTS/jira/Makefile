ORG := svg153
REPO := jira
PRODUCT ?= $(shell basename $(CURDIR))
PRODUCT_VERSION ?= $(shell git rev-parse --abbrev-ref HEAD | awk -F "/" '{print $$NF}')
IMAGE_NAME := $(ORG)/$(REPO)/$(PRODUCT):$(PRODUCT_VERSION)
DOCKERFILE ?= Dockerfile

.PHONY: all docker __build release

all: docker

docker: __build

__build:
	@docker build \
		-t $(IMAGE_NAME) \
		-f $(DOCKERFILE) \
		.

t get_issue_title: docker
	@docker run \
		--rm \
		-e GIT_PYTHON_REFRESH=quiet \
		-v $(PWD)/config.yaml:/app/config.yaml \
		-v $(PWD)/output:/app/output \
		$(IMAGE_NAME) \
		python3 ./get_issue_title.py \
			--yaml-input /app/config.yaml \
			--output /app/output/issues.json

e:
	@docker run \
	    -it \
		--rm \
		-e GIT_PYTHON_REFRESH=quiet \
		-v $(PWD)/config.yml:/app/config.yml \
		-v $(PWD)/output:/app/output \
		$(IMAGE_NAME) \
		/bin/sh