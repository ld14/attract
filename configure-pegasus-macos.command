#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
exec "$ROOT/scripts/configure-pegasus-macos.sh" "$@"
