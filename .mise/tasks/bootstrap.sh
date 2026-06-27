#!/usr/bin/env bash

#MISE description = "Bootsrap mise install"
#MISE hide = true

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

as_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

# Grant the current user a subuid/subgid range for rootless podman.
# Only the IDs the parent user namespace mapped are usable inside it, so derive
# the range from /proc/self/{uid,gid}_map instead of assuming the 100000 base
# that applies on a real host.
subid_range() {
	awk -v first="$2" \
		'{ last = $1 + $3 - 1; if (last > max) max = last } END { print first ":" max - first + 1 }' \
		"$1"
}

as_root sh -c "printf '%s:%s\n' \"$(whoami)\" \"$(subid_range /proc/self/uid_map "$(($(id -u) + 1))")\" >/etc/subuid"
as_root sh -c "printf '%s:%s\n' \"$(whoami)\" \"$(subid_range /proc/self/gid_map "$(($(id -g) + 1))")\" >/etc/subgid"

if systemctl --user is-system-running >/dev/null 2>&1; then
	systemctl --user enable --now podman.socket
else
	socket_path="$(podman info --format '{{.Host.RemoteSocket.Path}}')"
	mkdir -p "$(dirname "${socket_path}")"
	nohup podman system service --time=0 "unix://${socket_path}" >/dev/null 2>&1 &
fi
