#!/usr/bin/env bash

#MISE description = "Apply linters"

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

export CONTAINER_HOST="unix://$(podman info --format '{{.Host.RemoteSocket.Path}}')"
echo $CONTAINER_HOST
podman images
prek run --all-files
