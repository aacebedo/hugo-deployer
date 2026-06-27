#!/usr/bin/env bash

#MISE description = "Apply linters"

set -euxo pipefail
prek run --all-files
