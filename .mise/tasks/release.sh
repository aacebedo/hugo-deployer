#!/usr/bin/env sh

#MISE description = "Lint, test, security-scan, then publish a release"
#MISE depends = ["lint", "test", "security-scan"]
#MISE env = { GITHUB_TOKEN = { required = true, redact = true } }

set -eu
sudo ln -sf /usr/bin/podman /usr/local/bin/docker
semantic-release
