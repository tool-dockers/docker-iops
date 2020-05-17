VERSION:=$(shell semtag final -s minor -o)

# Git version information
GIT_COMMIT ?= $(shell git rev-parse --short HEAD)
GIT_DESCRIBE ?= $(shell git describe --tags --always --match "v*")
GIT_DIRTY=$(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)
VERSION_LABEL=$(shell semtag getlast | cut -c 2-)

# Docker image information
REGISTRY_NAME?=docker.io/acme
IMAGE_NAME=hello-world
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(VERSION)

#:help: help        | Displays the GNU makefile help
.PHONY: help
help: ; @sed -n 's/^#:help://p' Makefile

#:help: all         | Builds the Docker image and publishes it
.PHONY: all
all: build publish

#:help: build       | Builds the Docker image
.PHONY: build
build:
	@docker build --build-arg VERSION=$(VERSION_LABEL) --no-cache -t $(REGISTRY_NAME)/$(IMAGE_NAME):$(GIT_COMMIT) .

#:help: changelog   | Build the changelog
.PHONY: changelog
changelog:
	@git-chglog -o CHANGELOG.md --next-tag $(VERSION)
	@git add CHANGELOG.md && git commit -m "Updated CHANGELOG"
	@git push

#:help: precommit   | Lint the project files using pre-commit
.PHONY: precommit
precommit:
	@pre-commit run --all-files

#:help: publish     | Publishes the Docker image
.PHONY: publish
publish:
	@docker build --build-arg VERSION=$(VERSION_LABEL) --no-cache -t $(IMAGE_TAG) .
	@docker tag $(IMAGE_TAG) $(REGISTRY_NAME)/$(IMAGE_NAME):latest
	@docker push $(IMAGE_TAG)

#:help: release     | Release the product, setting the tag and pushing.
.PHONY: release
release:
	@semtag final -s minor
	@git push --follow-tags
