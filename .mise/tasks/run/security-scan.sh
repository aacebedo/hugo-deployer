#!/usr/bin/env bash

#MISE description = "Run security scans"

#MISE depends = ["build"]

#MISE env = { IMAGE_NAME = "{{vars.image_name}}" }
#MISE env = { COMMIT_SHA = "{{vars.commit_sha}}" }

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

image_tar="$(mktemp)"
trap 'rm -f "${image_tar}"' EXIT
podman save "${IMAGE_NAME}:${COMMIT_SHA}" -o "${image_tar}"

trivy image --format sarif \
	--input "${image_tar}" \
	--skip-version-check --output /tmp/trivy-results.sarif -d
