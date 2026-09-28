#!/usr/bin/env bash
set -euo pipefail

# Reports whether the secrets CI needs actually reached the runner — one entry per name in the env:
# block of .github/workflows/CI-test-foundry-stable.yml.
#
# Run by the test-foundry action before anything slow, as the optional `debug` script in
# package.json. It lives here rather than as a step in that workflow because the workflow is a copy
# of bao-base's and a step of our own would be drift — see the header there, and
# lib/bao-base/bin/optional-yarn-script for the mechanism.
#
# Diagnosing this early matters because the symptom is otherwise something failing many minutes
# later for a reason that looks like a broken test rather than a missing secret. The step this
# replaced checked only MAINNET_RPC_URL and ALCHEMY_API_URL, so a missing arbitrum, base or
# GITHUB_TOKEN secret was visible only as whatever went wrong downstream of it.

report_url() {
  local name="$1" value="$2"
  if [[ -z "$value" ]]; then
    echo "$name is empty"
  elif [[ "$value" == *"/v2/" ]]; then
    echo "$name has no API key on the end of it"
  else
    # The last path segment is the API key, so it is replaced rather than printed. GitHub masks a
    # registered secret in its own logs, but this same script runs on a developer's machine, where
    # nothing does.
    echo "$name appears set: '${value%/*}/***'"
  fi
}

# A secret that is not a URL has no non-secret part to show, so presence is all that can be reported
# — the URL form above would print everything up to the last "/", which for a bare token is nearly
# all of it. The length is given because a truncated secret is a real failure mode and the length
# alone does not help anyone use it.
report_presence() {
  local name="$1" value="$2"
  if [[ -z "$value" ]]; then
    echo "$name is empty"
  else
    echo "$name appears set (${#value} characters)"
  fi
}

report_url MAINNET_RPC_URL "${MAINNET_RPC_URL:-}"
report_url ARBITRUM_RPC_URL "${ARBITRUM_RPC_URL:-}"
report_url BASE_RPC_URL "${BASE_RPC_URL:-}"
report_url ALCHEMY_API_URL "${ALCHEMY_API_URL:-}"
report_presence GITHUB_TOKEN "${GITHUB_TOKEN:-}"
