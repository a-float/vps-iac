#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NANOBOT="$ROOT/submodules/nanobot"

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME}"
: "${DOCKERHUB_REPOSITORY:?Set DOCKERHUB_REPOSITORY}"

BUILD_ONLY=false
for arg in "$@"; do
  if [[ "$arg" == "--build-only" ]]; then
    BUILD_ONLY=true
  fi
done

UPSTREAM_SHA="$(git -C "$NANOBOT" rev-parse --short=12 HEAD)"
CUSTOM_SHA="$(git -C "$ROOT" rev-parse --short=12 HEAD)"

BASE_IMAGE="nanobot-base:${UPSTREAM_SHA}"

FINAL_IMAGE="docker.io/${DOCKERHUB_USERNAME}/${DOCKERHUB_REPOSITORY}"
FINAL_IMAGE_VERSION="${FINAL_IMAGE}:nanobot-${UPSTREAM_SHA}-custom-${CUSTOM_SHA}"
FINAL_IMAGE_LATEST="${FINAL_IMAGE}:latest"

echo "==> Versions:"
echo "    Nanobot: ${UPSTREAM_SHA}"
echo "    Custom:  ${CUSTOM_SHA}"
echo

echo "==> Building upstream Nanobot:"
echo "    ${BASE_IMAGE}"

docker build \
  --build-arg NANOBOT_CHANNELS="${NANOBOT_CHANNELS:-whatsapp}" \
  --build-arg NANOBOT_EXTRAS="${NANOBOT_EXTRAS:-}" \
  -f "$NANOBOT/Dockerfile" \
  -t "$BASE_IMAGE" \
  "$NANOBOT"

echo
echo "==> Building custom Nanobot:"
echo "    ${FINAL_IMAGE_VERSION}"
echo "    ${FINAL_IMAGE_LATEST}"

docker build \
  --build-arg NANOBOT_BASE_IMAGE="$BASE_IMAGE" \
  -f "$ROOT/nanobot-image/Dockerfile" \
  -t "$FINAL_IMAGE_VERSION" \
  -t "$FINAL_IMAGE_LATEST" \
  "$ROOT/nanobot-image"

if [[ "$BUILD_ONLY" != "true" ]]; then
echo
echo "==> Pushing custom Nanobot image:"

docker push "$FINAL_IMAGE_VERSION"
docker push "$FINAL_IMAGE_LATEST"

echo
echo "=========================================="
echo "Published:"
echo
echo "  ${FINAL_IMAGE_VERSION}"
echo "  ${FINAL_IMAGE_LATEST}"
echo "=========================================="
fi