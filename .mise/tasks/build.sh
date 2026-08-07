#!/usr/bin/env bash

#MISE description = "Build the container image"
#MISE env = { REPO_URL = "{{vars.repo_url}}" }
#MISE env = { REPO_NAME = "{{vars.repo_name}}" }
#MISE env = { REPO_OWNER = "{{vars.repo_owner}}" }
#MISE env = { IMAGE_NAME = "{{vars.image_name}}" }
#MISE env = { COMMIT_SHA = "{{vars.commit_sha}}" }

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

export CONTAINER_HOST="unix://$(podman info --format '{{.Host.RemoteSocket.Path}}')"
echo $CONTAINER_HOST
podman build --format docker -t "${IMAGE_NAME}:${COMMIT_SHA}" \
	--label "org.opencontainers.image.source=${REPO_URL}" \
	--label "org.opencontainers.image.description=Development container base" \
	--label "org.opencontainers.image.licenses=MIT" \
	--label "org.opencontainers.image.title=${REPO_NAME}" \
	--label "org.opencontainers.image.vendor=${REPO_OWNER}" .

podman info --format '{{.Host.RemoteSocket.Path}}'
podman images
