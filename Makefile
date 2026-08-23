# Docker image build and push helpers
# Usage: make build-image    # build images (without pushing)
# Usage: make push-image     # push built images
# Usage: make help           # show this help

# Top-level SHA variables
NANOBOT_SHA := $(shell git -C submodules/nanobot rev-parse --short=12 HEAD)
CUSTOM_SHA := $(shell git -C . rev-parse --short=12 HEAD)

.PHONY: build-image push-image help

# Build the docker images using the shared build-image.sh script
# --build-only flag prevents pushing, so make push-image can push later
build-image: ## Build the docker images
	@bash nanobot-image/build-image.sh --build-only

# Push the built docker images
push-image: ## Push the built docker images
	@bash nanobot-image/build-image.sh

# Show this help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "} {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
