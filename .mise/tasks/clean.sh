#!/usr/bin/env bash

#MISE description = "Remove generated Vale configuration files"

set -euxo pipefail
rm -rf .vale/.vale-config .vale/Google
