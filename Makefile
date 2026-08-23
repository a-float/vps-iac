# Docker image build and push helpers
# Usage: make build-image    # build images
# Usage: make push-image     # push built images
# Usage: make help           # show this help

.PHONY: build-image push-image help

# Build the docker images using the shared build-image.sh script
build-image: ## Build the docker images
	@bash nanobot-image/build-image.sh

# Push the built docker images
push-image: ## Push the built docker images
	@docker push nanobot-base:${UPSTREAM_SHA}
	@docker push docker.io/afloaty/nanobot:nanobot-${UPSTREAM_SHA}-custom-${CUSTOM_SHA}
	@docker push docker.io/afloaty/nanobot:latest

# Show this help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "} {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'