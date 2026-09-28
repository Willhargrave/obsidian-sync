#!/usr/bin/env bash
set -euo pipefail

VAULT_DIR="${VAULT_DIR:-$HOME/ObsidianVault}"
FOLDER_ID="obsidian-main"
SYNCTHING_URL="http://127.0.0.1:8384"
REPLACE_STIGNORE=false

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

usage() {
  cat <<'EOF'
Usage: ./install-macos.sh [--replace-stignore]

Options:
  --replace-stignore  Back up a differing vault .stignore, then replace it
  -h, --help          Show this help

Set VAULT_DIR to override the default vault path:
  VAULT_DIR=/custom/path ./install-macos.sh
EOF
}

while (($# > 0)); do
  case "$1" in
    --replace-stignore)
      REPLACE_STIGNORE=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac
  shift
done

SCRIPT_DIR="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" || exit 1
  pwd -P
)"
SOURCE_STIGNORE="$SCRIPT_DIR/.stignore"
TARGET_STIGNORE="$VAULT_DIR/.stignore"

if [[ ! -f "$SOURCE_STIGNORE" ]]; then
  log_error "Repository ignore file not found: $SOURCE_STIGNORE"
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  log_error "Homebrew is required but was not found. Install it from https://brew.sh, then run this script again."
  exit 1
fi

if ! command -v syncthing >/dev/null 2>&1; then
  log_info "Syncthing is not installed. Installing it with Homebrew."
  brew install syncthing
else
  log_info "Syncthing is already installed: $(command -v syncthing)"
fi

if [[ -e "$VAULT_DIR" && ! -d "$VAULT_DIR" ]]; then
  log_error "Vault path exists but is not a directory: $VAULT_DIR"
  exit 1
fi

if [[ -d "$VAULT_DIR" ]]; then
  log_info "Vault directory already exists; leaving its contents unchanged: $VAULT_DIR"
else
  mkdir -p -- "$VAULT_DIR"
  log_info "Created vault directory: $VAULT_DIR"
fi

if [[ ! -e "$TARGET_STIGNORE" ]]; then
  cp -- "$SOURCE_STIGNORE" "$TARGET_STIGNORE"
  log_info "Copied .stignore into the vault."
elif [[ ! -f "$TARGET_STIGNORE" ]]; then
  log_error "The vault .stignore path exists but is not a regular file: $TARGET_STIGNORE"
  exit 1
elif cmp -s -- "$SOURCE_STIGNORE" "$TARGET_STIGNORE"; then
  log_info "The vault .stignore already matches the repository version."
elif [[ "$REPLACE_STIGNORE" == true ]]; then
  timestamp="$(date '+%Y%m%d-%H%M%S')"
  backup_path="${TARGET_STIGNORE}.backup-${timestamp}"
  cp -p -- "$TARGET_STIGNORE" "$backup_path"
  cp -- "$SOURCE_STIGNORE" "$TARGET_STIGNORE"
  log_warn "Replaced the differing vault .stignore after saving: $backup_path"
else
  log_warn "The vault .stignore differs from the repository version. It was not changed."
  log_warn "Review it, or rerun with --replace-stignore to back it up and replace it."
fi

log_info "Starting Syncthing with Homebrew services."
brew services start syncthing

service_status=""
for ((attempt = 1; attempt <= 10; attempt++)); do
  service_status="$(brew services list | awk '$1 == "syncthing" { print $2 }')"
  [[ "$service_status" == "started" ]] && break
  sleep 1
done
if [[ "$service_status" != "started" ]]; then
  log_error "Syncthing did not report a started service state. Current state: ${service_status:-unknown}"
  log_error "Check Homebrew service logs, then run: brew services restart syncthing"
  exit 1
fi
log_info "Syncthing service is running."

if ! open "$SYNCTHING_URL"; then
  log_warn "Could not open a browser automatically. Open $SYNCTHING_URL yourself."
fi

cat <<EOF

[INFO] Finish setup in the Syncthing UI at $SYNCTHING_URL
  1. Use Actions > Show ID to get this device's Device ID.
  2. Add a folder with Folder ID: $FOLDER_ID
  3. Set its folder path to: $VAULT_DIR
  4. Enable Simple File Versioning and keep about 10 versions.
  5. Add each remote device, then share $FOLDER_ID with it.

[INFO] Pairing and folder sharing stay in the Syncthing UI. This script does not edit config.xml.
EOF
