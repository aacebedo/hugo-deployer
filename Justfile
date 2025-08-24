# Justfile for hugo-deployer project

[private]
repo_name := shell('git ls-remote --get-url origin | sed -E "s/.*[:\\/]([^\\/]+)\\/([^\\/]+)(\\.git)?$/\\2/" | sed "s/\\.git$//"') # editorconfig-checker-disable-line
[private]
repo_owner := shell('git ls-remote --get-url origin | sed -E "s/.*[:\\/]([^\\/]+)\\/([^\\/]+)(\\.git)?$/\\1/"')
[private]
docker_tag := "ghcr.io/" + repo_owner + "/" + repo_name + ":latest"
[private]
repo_url := "https://github.com/" + repo_owner + "/" + repo_name

# Default recipe to display available commands
default:
	just --list

# Run linting using pre-commit
lint:
	vale sync
	pre-commit run --all-files

# Build the Docker image
build:
	docker build -t {{docker_tag}} \
				--label "org.opencontainers.image.source={{repo_url}}" \
				--label "org.opencontainers.image.description=Hugo deployer development container" \
				--label "org.opencontainers.image.licenses=MIT" \
				--label "org.opencontainers.image.title={{repo_name}}" \
				--label "org.opencontainers.image.vendor={{repo_owner}}" .

test: build
	#!/usr/bin/env sh
	trap 'podman-compose down' EXIT
	export GIT_REPO_URL="https://github.com/aacebedo/hugo-deployer-example.git"
	export GIT_USERNAME=johndoe
	export GIT_TOKEN=secret_token
	export GIT_BRANCH=main
	export API_KEY=secret_api_key
	export PORT=8080
	podman-compose up --build -d
	curl --retry 5 --retry-delay 5 --retry-all-errors localhost:8080 > /dev/null

# Run security scan using trivy
security-scan: build
	#!/usr/bin/env bash
	set -euxo pipefail
	TEMP_DIR=$(mktemp -d)
	docker save {{docker_tag}} | gzip > "$TEMP_DIR/image.tar.gz"
	trivy image --input "$TEMP_DIR/image.tar.gz" --format sarif --output /tmp/trivy-results.sarif
	rm -rf "$TEMP_DIR"

release: lint security-scan
	semantic-release
