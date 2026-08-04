#!/usr/bin/env bash

#MISE description = "Bootsrap mise install"

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

if systemctl --user is-system-running >/dev/null 2>&1; then
	systemctl --user enable --now podman.socket
else
	socket_path="$(podman info --format '{{.Host.RemoteSocket.Path}}')"
	mkdir -p "$(dirname "${socket_path}")"
	nohup podman system service --time=0 "unix://${socket_path}" >/dev/null 2>&1 &
fi
