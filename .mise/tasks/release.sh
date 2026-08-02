#!/usr/bin/env bash

#MISE description = "Publish a release"
#MISE depends = ["lint", "test", "security-scan"]
#MISE env = { REGISTRY_USERNAME = { required = true } }
#MISE env = { REGISTRY_PASSWORD = { required = true, redact = true } }
#MISE env = { GITHUB_TOKEN = { required = true, redact = true } }
#MISE env = { IMAGE_NAME = "{{vars.image_name}}" }
#MISE env = { REPO_OWNER = "{{vars.repo_owner}}" }
#MISE env = { REPO_NAME = "{{vars.repo_name}}" }
#MISE env = { COMMIT_SHA = "{{vars.commit_sha}}" }

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

podman login ghcr.io -u "${REGISTRY_USERNAME}" -p "${REGISTRY_PASSWORD}"
cog bump --auto --skip-ci
