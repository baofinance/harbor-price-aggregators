#!/usr/bin/env bash
set -euo pipefail

# Live fork suites inflate `latestAnswer` gas (live RPC vs mocks) and 429 on GitHub.
# `yarn test` still runs them locally. `yarn gas` and `yarn coverage` always omit
# them so the committed regression files match GitHub. Direct `forge test` is
# unchanged: forks included.
target=""
for target in "$@"; do
  :
done
case "$target" in
  gas | coverage)
    export FOUNDRY_PROFILE=github
    ;;
  test)
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
      export FOUNDRY_PROFILE=github
    fi
    ;;
esac

exec ./lib/bao-base/run "$@"
