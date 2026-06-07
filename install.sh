#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
LIBEXEC_DIR="$PREFIX/libexec/pawkup"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
MISSING_DEPENDENCY_LABELS=()
MISSING_DEPENDENCY_PACKAGES=()

DEPENDENCIES=(
  "python3:python3:Python 3"
  "restic:restic:restic"
  "rclone:rclone:rclone"
  "rsync:rsync:rsync"
)

usage() {
  cat <<EOF
Usage:
  ./install.sh [--prefix DIR]

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

detect_package_manager() {
  local candidate

  for candidate in apt-get dnf yum pacman zypper apk; do
    if command -v "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
    return
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required to install missing dependencies." >&2
    exit 1
  fi

  sudo "$@"
}

find_missing_dependencies() {
  local dependency command_name package_name label rest

  MISSING_DEPENDENCY_LABELS=()
  MISSING_DEPENDENCY_PACKAGES=()

  for dependency in "${DEPENDENCIES[@]}"; do
    command_name="${dependency%%:*}"
    rest="${dependency#*:}"
    package_name="${rest%%:*}"
    label="${rest#*:}"

    if ! command -v "$command_name" >/dev/null 2>&1; then
      MISSING_DEPENDENCY_LABELS+=("$label")
      MISSING_DEPENDENCY_PACKAGES+=("$package_name")
    fi
  done
}

install_packages() {
  local package_manager="$1"
  shift

  case "$package_manager" in
    apt-get)
      run_as_root apt-get update
      run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
      ;;
    dnf)
      run_as_root dnf install -y "$@"
      ;;
    yum)
      run_as_root yum install -y "$@"
      ;;
    pacman)
      run_as_root pacman -Sy --needed --noconfirm "$@"
      ;;
    zypper)
      run_as_root zypper --non-interactive install "$@"
      ;;
    apk)
      run_as_root apk add "$@"
      ;;
    *)
      echo "Unsupported package manager: $package_manager" >&2
      exit 1
      ;;
  esac
}

ensure_dependencies() {
  local package_manager answer label

  find_missing_dependencies
  if [ "${#MISSING_DEPENDENCY_PACKAGES[@]}" -eq 0 ]; then
    return
  fi

  package_manager="$(detect_package_manager)" || {
    echo "Missing dependencies:" >&2
    printf '  %s\n' "${MISSING_DEPENDENCY_LABELS[@]}" >&2
    echo "Install them with your package manager, then rerun ./install.sh." >&2
    exit 1
  }

  echo "Pawkup needs these missing dependencies:"
  for label in "${MISSING_DEPENDENCY_LABELS[@]}"; do
    printf '  %s\n' "$label"
  done
  printf 'Install missing packages now with %s? [y/N] ' "$package_manager"

  if [ -t 0 ]; then
    read -r answer
  else
    echo
    echo "Cannot prompt in non-interactive mode. Install dependencies first, then rerun ./install.sh." >&2
    exit 1
  fi

  case "$answer" in
    y|Y|yes|YES)
      ;;
    *)
      echo "Install cancelled. Pawkup was not installed." >&2
      exit 1
      ;;
  esac

  install_packages "$package_manager" "${MISSING_DEPENDENCY_PACKAGES[@]}"

  find_missing_dependencies
  if [ "${#MISSING_DEPENDENCY_PACKAGES[@]}" -ne 0 ]; then
    echo "Some dependencies are still missing after package installation:" >&2
    printf '  %s\n' "${MISSING_DEPENDENCY_LABELS[@]}" >&2
    exit 1
  fi
}

ensure_dependencies

mkdir -p "$BIN_DIR" "$LIBEXEC_DIR"

install -m 0755 "$REPO_DIR/bin/pawkup" "$BIN_DIR/pawkup"
install -m 0755 "$REPO_DIR/libexec/pawkup/pawkup_backup" "$LIBEXEC_DIR/pawkup_backup"
install -m 0755 "$REPO_DIR/libexec/pawkup/pawkup_restore" "$LIBEXEC_DIR/pawkup_restore"
install -m 0755 "$REPO_DIR/libexec/pawkup/pawkup_check" "$LIBEXEC_DIR/pawkup_check"
install -m 0755 "$REPO_DIR/libexec/pawkup/pawkup_backup_scheduler" "$LIBEXEC_DIR/pawkup_backup_scheduler"
install -m 0644 "$REPO_DIR/libexec/pawkup/pawkup_shared" "$LIBEXEC_DIR/pawkup_shared"

cat <<EOF
Pawkup installed.

Binary:  $BIN_DIR/pawkup
Helpers: $LIBEXEC_DIR

Make sure $BIN_DIR is on your PATH, then run:
  pawkup
EOF
