#!/usr/bin/env sh

#MISE description = "Remove generated Vale configuration files"

set -eu
rm -rf .vale/.vale-config .vale/Google
