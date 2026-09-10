#!/usr/bin/env bash

#MISE description = "Bootsrap mise"
#MISE hide = true

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

# This bootstrap only makes sense inside a devcontainer: it derives a
# subuid/subgid range from the container's own (already remapped) user
# namespace and overwrites /etc/subuid and /etc/subgid system-wide. On a
# standard machine that would clobber the host's real rootless-podman/docker
# ID mappings, so skip entirely when not containerized.
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
	printf "Skipping rootless podman subuid/subgid bootstrap: not running inside a container.\n"
	exit 0
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
