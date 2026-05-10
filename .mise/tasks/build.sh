#!/usr/bin/env sh

#MISE description = "Build the container image"
#MISE depends = ["lint"]
#MISE env = { DOCKER_TAG = "{{vars.docker_tag}}" }
#MISE env = { REPO_URL = "{{vars.repo_url}}" }
#MISE env = { REPO_NAME = "{{vars.repo_name}}" }
#MISE env = { REPO_OWNER = "{{vars.repo_owner}}" }

set -eu
podman build -t "$DOCKER_TAG" \
	--label "org.opencontainers.image.source=$REPO_URL" \
	--label "org.opencontainers.image.description=Development container base" \
	--label "org.opencontainers.image.licenses=MIT" \
	--label "org.opencontainers.image.title=$REPO_NAME" \
	--label "org.opencontainers.image.vendor=$REPO_OWNER" .
