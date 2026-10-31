
# Docker image build and push helpers
# Usage: make build-image     # build images (without pushing)
# Usage: make push-image      # push built images
# Usage: make backup-nanobot  # download remote nanobot config backup
# Usage: make help            # show this help

# Top-level SHA variables
NANOBOT_SHA := $(shell git -C submodules/nanobot rev-parse --short=12 HEAD)
CUSTOM_SHA := $(shell git -C . rev-parse --short=12 HEAD)

.DOCKER_LOGIN := false

# Backup configuration
BACKUP_HOST := mikrus-root
BACKUP_REMOTE_DIR := /opt/nanobot/.nanobot
BACKUP_LOCAL_DIR := ./backups
BACKUP_TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)
BACKUP_REMOTE_FILE := /tmp/nanobot-backup-$(BACKUP_TIMESTAMP).tar.gz
BACKUP_LOCAL_FILE := $(BACKUP_LOCAL_DIR)/nanobot-backup-$(BACKUP_TIMESTAMP).tar.gz

.PHONY: build-image push-image backup-nanobot help

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

backup-nanobot: ## Download remote nanobot config backup
	@mkdir -p "$(BACKUP_LOCAL_DIR)"
	@echo "Creating backup on $(BACKUP_HOST)..."
	@ssh "$(BACKUP_HOST)" "sudo tar -czf '$(BACKUP_REMOTE_FILE)' -C /opt/nanobot .nanobot"
	@echo "Downloading backup..."
	@scp "$(BACKUP_HOST):$(BACKUP_REMOTE_FILE)" "$(BACKUP_LOCAL_FILE)"
	@echo "Removing remote temporary archive..."
	@ssh "$(BACKUP_HOST)" "rm -f '$(BACKUP_REMOTE_FILE)'"
	@echo "Backup completed: $(BACKUP_LOCAL_FILE)"

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "} {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
