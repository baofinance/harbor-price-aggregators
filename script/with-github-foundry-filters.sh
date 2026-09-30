#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions is the only place that selects foundry.toml's `github` profile,
# which omits the live fork suites. A local `yarn test` or `yarn CI` leaves
# FOUNDRY_PROFILE alone, so those suites still run. Direct `forge test` is the
# same as local yarn: forks included.
if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
  export FOUNDRY_PROFILE=github
fi

exec ./lib/bao-base/run "$@"
