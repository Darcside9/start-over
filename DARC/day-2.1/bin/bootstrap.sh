#!/usr/bin/env bash
# Bootstrap wrapper for D∆RC installer
# - performs minimal sanity checks and hand-offs to Python CLI

set -euo pipefail
trap 'rc=$?; if [ "$rc" -ne 0 ]; then echo "[darc-bootstrap] Exited with code $rc" >&2; fi; exit $rc' EXIT

log() { printf '%s\n' "[darc-bootstrap] $*"; }
err() { printf '%s\n' "[darc-bootstrap][ERR] $*" >&2; }

# Ensure script runs from repository root if invoked inside repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Require root for system-level installs
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
	err "This installer needs to run as root. Please run with sudo or as root."
	exit 2
fi

# Ensure python3 available
if ! command -v python3 >/dev/null 2>&1; then
	err "python3 not found. Please install Python 3.10+ and rerun."
	exit 3
fi

# Export a default AI_HOME if not set
: "${AI_HOME:=/opt/darc-ai}"
export AI_HOME

# Run the Python CLI module
exec python3 -m darc_installer.cli "$@"
