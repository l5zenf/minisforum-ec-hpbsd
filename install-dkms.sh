#!/bin/bash
# Install the minisforum_ec DKMS module for persistent, per-kernel builds.
# Usage: sudo bash install-dkms.sh
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/module"
VERSION="$(sed -n 's/^PACKAGE_VERSION="\(.*\)"/\1/p' "$SRC/dkms.conf")"
NAME=minisforum_ec

[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
[[ -n "$VERSION" ]] || { echo "no PACKAGE_VERSION in dkms.conf" >&2; exit 1; }

echo "==> Installing $NAME/$VERSION to /usr/src"
rm -rf "/usr/src/$NAME-$VERSION"
cp -r "$SRC" "/usr/src/$NAME-$VERSION"

echo "==> dkms add + install (builds for the running kernel)"
dkms add -m "$NAME" -v "$VERSION" 2>/dev/null || true   # already added is fine
dkms install -m "$NAME" -v "$VERSION"

echo "==> Enabling module load at boot"
echo "$NAME" > /etc/modules-load.d/$NAME.conf

echo "==> Done. Loaded on the next boot; or now with: sudo modprobe $NAME"
dkms status
