#!/bin/sh
set -euo

HELM_PLUGINS_VALUE=$(
	JQ_FILTER='.[] | select(.active == true) | .install_path'

	result=""
	for install_path in $(mise ls -J http:helm-kubeconform | jq -r "$JQ_FILTER"); do
		if [ -n "$result" ]; then
			result="${result}:${install_path}"
		else
			result="${install_path}"
		fi
	done
	echo "$result"
)
export HELM_PLUGINS="${HELM_PLUGINS_VALUE}"
