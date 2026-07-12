#!/usr/bin/env bash

#MISE description = "Build and run the container image"
#MISE depends = ["build"]

set -euxo pipefail
trap 'podman-compose down' EXIT
export GIT_REPO_URL="github.com/aacebedo/hugo-deployer-example.git"
export GIT_USERNAME=johndoe
export GIT_TOKEN=secret_token
export GIT_BRANCH=main
export UPDATE_API_KEY=secret_api_key
export PORT=8080
podman-compose up --build -d
curl --retry 5 --retry-delay 5 --retry-all-errors localhost:8080 >/dev/null
