# Docker image build and push helpers
# Usage: make build-image    # build images (without pushing)
# Usage: make push-image     # push built images
# Usage: make help           # show this help

# Top-level SHA variables
NANOBOT_SHA := $(shell git -C submodules/nanobot rev-parse --short=12 HEAD)
CUSTOM_SHA := $(shell git -C . rev-parse --short=12 HEAD)

.DOCKER_LOGIN := false

.PHONY: build-image push-image help

build-image: ## Build the docker images
	@echo "Building base image nanobot-base:${NANOBOT_SHA}"
	@docker build \
		--build-arg NANOBOT_CHANNELS="${NANOBOT_CHANNELS:-whatsapp}" \
		--build-arg NANOBOT_EXTRAS="${NANOBOT_EXTRAS:-}" \
		-f "submodules/nanobot/Dockerfile" \
		-t "nanobot-base:${NANOBOT_SHA}" \
		"submodules/nanobot"
	@echo "Building custom image"
	@docker build \
		--build-arg NANOBOT_BASE_IMAGE="nanobot-base:${NANOBOT_SHA}" \
		-f "Dockerfile" \
		-t "docker.io/afloaty/nanobot:nanobot-${NANOBOT_SHA}-custom-${CUSTOM_SHA}" \
		-t "docker.io/afloaty/nanobot:latest" \
		.

push-image: ## Push the built docker images
	@docker push "docker.io/afloaty/nanobot:nanobot-${NANOBOT_SHA}-custom-${CUSTOM_SHA}"
	@docker push "docker.io/afloaty/nanobot:latest"

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "} {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
