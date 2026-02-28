#!/usr/bin/env sh
set -eu

NODE_PATH_VALUE=$(
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
