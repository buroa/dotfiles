#!/usr/bin/env bash
set -euo pipefail
# Bootstrap mise before files are applied so the after-hook can read the config.
# Selected via .chezmoiignore (truenas/fedora only). On Fedora IoT mise usually
# comes from rpm-ostree, so the guard below makes this a no-op when it is present.
if ! command -v mise >/dev/null && [ ! -x "$HOME/.local/bin/mise" ]; then
    curl -fsSL https://mise.run | sh
fi
