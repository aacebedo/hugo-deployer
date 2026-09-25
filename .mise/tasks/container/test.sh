#!/usr/bin/env bash

#MISE description = "Smoke test the built container image with the example compose stack"
#MISE depends = ["container:build"]
#MISE env.COMMIT_SHA = "{{vars.commit_sha}}"

set -euo pipefail

cd example
set -a
# shellcheck disable=SC1091
source .env
set +a

trap 'podman-compose down' EXIT

podman-compose -f docker-compose.yaml up -d
curl --retry 5 --retry-delay 5 --retry-all-errors "localhost:${PORT}" >/dev/null
