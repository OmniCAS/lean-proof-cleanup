#!/usr/bin/env bash
# Fetch an official Lean 4 Linux toolchain into the workspace and verify it.
# Usage: fetch_toolchain.sh WORKSPACE VERSION SHA256      (VERSION like 4.35.0 or 4.34.0-rc2)
# The archive is taken from MIRROR (default: a university mirror of the elan release files) and
# accepted only if its SHA-256 equals the digest published for the official GitHub release asset
# (read it from https://api.github.com/repos/leanprover/lean4/releases/tags/vVERSION).
# Nothing outside WORKSPACE is touched; elan is not involved (call bin/lake by path).
set -euo pipefail
WS=$1; V=$2; SHA=$3
MIRROR=${MIRROR:-https://mirror.sjtu.edu.cn/elan/leanprover/lean4/releases/download}
mkdir -p "$WS/dl" "$WS/toolchains"
F="$WS/dl/lean-$V-linux.tar.zst"
if [ ! -f "$F" ]; then
  curl -sSfL --retry 5 --max-time 1800 -o "$F.part" "$MIRROR/v$V/lean-$V-linux.tar.zst"
  mv "$F.part" "$F"
fi
GOT=$(sha256sum "$F" | cut -d' ' -f1)
if [ "$GOT" != "$SHA" ]; then echo "CHECKSUM MISMATCH for $V: got $GOT"; exit 1; fi
if [ ! -x "$WS/toolchains/lean-$V-linux/bin/lean" ]; then
  tar -I zstd -xf "$F" -C "$WS/toolchains"
fi
"$WS/toolchains/lean-$V-linux/bin/lean" --version
echo "TOOLCHAIN_OK $V"
