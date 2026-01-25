#!/bin/sh
set -e

NODE_PATH_VALUE=$(
	export MISE_NO_ENV=1 MISE_NO_HOOKS=1
	eval "$(mise activate bash)"

	JQ_FILTER='to_entries | .[] | select(.key | startswith("npm:")) |
		.value[] | select(.active == true) | .install_path'

	result=""
	for install_path in $(mise ls -J | jq -r "$JQ_FILTER"); do
		if [ -n "$result" ]; then
			result="${result}:${install_path}/5/node_modules"
		else
			result="${install_path}/5/node_modules"
		fi
	done
	echo "$result"
)
export NODE_PATH="${NODE_PATH_VALUE}"
