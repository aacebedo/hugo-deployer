#!/usr/bin/env bash

#MISE description = "Bump pinned dependencies with Updatecli"

#USAGE flag "-a --apply" help="Apply changes and open pull requests (default: dry run diff only)"

#MISE env = { UPDATECLI_GITHUB_TOKEN = { required = true, redact = true } }

set -euo pipefail

if [ -z "${MISE_TASK_NAME:-}" ]; then
	printf "\033[31mError: this script must be run via 'mise run <task>' (not executed directly).\033[0m\n" >&2
	exit 1
fi

command="diff"
if [ "${usage_apply:-false}" = "true" ]; then
	command=apply
fi

updatecli pipeline "${command}" --config .updatecli/manifests --values .updatecli/values.yaml
