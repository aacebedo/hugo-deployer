#!/usr/bin/env bash

#MISE description = "Build and run the container image"
#MISE depends = ["build"]

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

trap 'podman-compose down' EXIT
export GIT_REPO_URL="github.com/aacebedo/hugo-deployer-example.git"
export GIT_USERNAME=johndoe
export GIT_TOKEN=secret_token
export GIT_BRANCH=main
export UPDATE_API_KEY=secret_api_key
export PORT=8080
podman-compose up --build -d
curl --retry 5 --retry-delay 5 --retry-all-errors localhost:8080 >/dev/null
