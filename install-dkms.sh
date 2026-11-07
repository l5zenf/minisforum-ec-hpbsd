#!/bin/bash
# Install the minisforum_ec DKMS module for persistent, per-kernel builds.
# Usage: sudo bash install-dkms.sh
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/module"
VERSION="$(sed -n 's/^PACKAGE_VERSION="\(.*\)"/\1/p' "$SRC/dkms.conf")"
PKG="$(sed -n 's/^PACKAGE_NAME="\(.*\)"/\1/p' "$SRC/dkms.conf")"
MOD="$(sed -n 's/^BUILT_MODULE_NAME\[0\]="\(.*\)"/\1/p' "$SRC/dkms.conf")"

[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
[[ -n "$VERSION" && -n "$PKG" && -n "$MOD" ]] || { echo "bad dkms.conf" >&2; exit 1; }
echo "==> package: $PKG/$VERSION, module: $MOD"

# Clean trees from earlier attempts and older versions, under either spelling.
for tree in "$PKG" "${PKG//-/_}"; do
	for v in $(dkms status 2>/dev/null | awk -v t="$tree" -F'[ /,]' '$1 == t {print $2}' | sort -u); do
		dkms remove "$tree/$v" --all 2>/dev/null || true
	done
	rm -rf "/var/lib/dkms/$tree"
done
rm -rf /usr/src/"$PKG"-*

echo "==> Installing source to /usr/src/$PKG-$VERSION"
rm -rf "/usr/src/$PKG-$VERSION"
cp -r "$SRC" "/usr/src/$PKG-$VERSION"

echo "==> dkms add + install (builds for the running kernel)"
dkms add -m "$PKG" -v "$VERSION"
dkms install -m "$PKG" -v "$VERSION"

echo "==> Enabling module load at boot"
echo "$MOD" > /etc/modules-load.d/$MOD.conf

echo "==> Done. Loaded on the next boot; or now with: sudo modprobe $MOD"
dkms status
