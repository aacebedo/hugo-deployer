# editorconfig-checker-disable

[private]
repo_name := shell('git ls-remote --get-url origin | sed -E "s/.*[:\\/]([^\\/]+)\\/([^\\/]+)(\\.git)?$/\\2/" | sed "s/\\.git$//"')
[private]
repo_owner := shell('git ls-remote --get-url origin | sed -E "s/.*[:\\/]([^\\/]+)\\/([^\\/]+)(\\.git)?$/\\1/"')

# editorconfig-checker-enable

[private]
docker_tag := "ghcr.io/" + repo_owner + "/" + repo_name + ":latest"
[private]
repo_url := "https://github.com/" + repo_owner + "/" + repo_name

default:
    just --list

lint:
    pre-commit run --all-files

build:
    podman build -t {{ docker_tag }} \
      --label "org.opencontainers.image.source={{ repo_url }}" \
      --label "org.opencontainers.image.description=Hugo deployer development container" \
      --label "org.opencontainers.image.licenses=MIT" \
      --label "org.opencontainers.image.title={{ repo_name }}" \
      --label "org.opencontainers.image.vendor={{ repo_owner }}" .

test: build
    #!/usr/bin/env sh
    trap 'podman-compose down' EXIT
    export GIT_REPO_URL="github.com/aacebedo/hugo-deployer-example.git"
    export GIT_USERNAME=johndoe
    export GIT_TOKEN=secret_token
    export GIT_BRANCH=main
    export UPDATE_API_KEY=secret_api_key
    export PORT=8080
    podman-compose up --build -d
    curl --retry 5 --retry-delay 5 --retry-all-errors localhost:8080 > /dev/null

security-scan: build
    #!/usr/bin/env bash
    set -euxo pipefail
    TEMP_DIR=$(mktemp -d)
    docker save {{ docker_tag }} | gzip > "$TEMP_DIR/image.tar.gz"
    trivy image --input "$TEMP_DIR/image.tar.gz" --format sarif \
      --skip-version-check --output /tmp/trivy-results.sarif
    rm -rf "$TEMP_DIR"

release: lint test security-scan
    semantic-release

clean:
    rm -rf .vale/.vale-config .vale/Google
