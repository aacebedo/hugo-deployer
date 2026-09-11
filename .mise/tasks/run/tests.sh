#!/usr/bin/env bash

#MISE description = "Run tests"

#MISE depends = ["build", "run:security-scan"]

#MISE env = { IMAGE_NAME = "{{vars.image_name}}" }
#MISE env = { COMMIT_SHA = "{{vars.commit_sha}}" }

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

helm unittest "${MISE_PROJECT_ROOT}/charts/hugo-deployer"

cd "${MISE_PROJECT_ROOT}/example"
set -a
# shellcheck disable=SC1091
source .env
set +a

trap 'podman-compose down' EXIT

podman-compose -f docker-compose.yaml up -d
curl --retry 5 --retry-delay 5 --retry-all-errors "localhost:${PORT}" >/dev/null
