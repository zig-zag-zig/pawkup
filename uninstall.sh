#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
LIBEXEC_DIR="$PREFIX/libexec/pawkup"

usage() {
  cat <<EOF
Usage:
  ./uninstall.sh [--prefix DIR]

Environment:
  PREFIX    Install prefix. Defaults to $HOME/.local
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --prefix)
      if [ "$#" -lt 2 ]; then
        echo "Missing value for --prefix" >&2
        exit 1
      fi
      PREFIX="$2"
      BIN_DIR="$PREFIX/bin"
      LIBEXEC_DIR="$PREFIX/libexec/pawkup"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user stop pawkup-backup.timer pawkup-backup.service >/dev/null 2>&1 || true
  systemctl --user disable pawkup-backup.timer >/dev/null 2>&1 || true
  rm -f "$HOME/.config/systemd/user/pawkup-backup.timer" "$HOME/.config/systemd/user/pawkup-backup.service"
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

rm -f "$BIN_DIR/pawkup"
rm -rf "$LIBEXEC_DIR"

cat <<EOF
Pawkup uninstalled from:
  $BIN_DIR/pawkup
  $LIBEXEC_DIR

Configuration, repositories, passwords, and logs were left in place.
EOF
