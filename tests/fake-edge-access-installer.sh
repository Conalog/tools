#!/usr/bin/env bash

set -euo pipefail

test -n "${GH_TOKEN:-}"
touch "${EDGE_ACCESS_TEST_MARKER:?}"
