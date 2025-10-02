#!/usr/bin/env bash

# Merges COPR downloads into flightctl-rpm repository

set -euo pipefail

# Configuration
OUTPUT_DIR=".output"
COPR_DOWNLOAD_DIR="${1:-$OUTPUT_DIR/copr-rpms-temp}"
REPO_OUTPUT_DIR="${2:-$(git rev-parse --show-toplevel)}"
INPUT_DIR="$(pwd)"  # Current directory where script is run from (flightctl-rpm)
TEMPLATES_DIR="$INPUT_DIR/templates"  # Templates are in the current directory

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show usage
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [copr_download_dir] [repo_output_dir]"
    echo "Example: $0 .output/copr-rpms-temp .output/flightctl-rpm"
    exit 1
fi

# Validate inputs
if [ ! -d "$COPR_DOWNLOAD_DIR" ]; then
    error "COPR download directory not found: $COPR_DOWNLOAD_DIR"
    exit 1
fi

rpm_count=$(find "$COPR_DOWNLOAD_DIR" -name "*.rpm" | wc -l)
if [ $rpm_count -eq 0 ]; then
    error "No RPM files found in $COPR_DOWNLOAD_DIR"
    exit 1
fi

log "Processing $rpm_count RPM files from $COPR_DOWNLOAD_DIR"

# Auto-detect the latest version
mapfile -t _VERSIONS < <(
  find "$COPR_DOWNLOAD_DIR" -name '*.rpm' -exec sh -c '
    rpm -qp --qf "%{VERSION}\n" "$1" 2> /dev/null || echo "unknown"
  ' _ {} \;
)
if command -v rpmdev-sort &>/dev/null && printf '%s\n' "${_VERSIONS[@]}" | rpmdev-sort >/dev/null 2>&1; then
  LATEST_VERSION=$(printf '%s\n' "${_VERSIONS[@]}" | rpmdev-sort | tail -1)
else
  LATEST_VERSION=$(printf '%s\n' "${_VERSIONS[@]}" | sort -V | tail -1)
fi

log "Detected latest version: $LATEST_VERSION"

# Copy RPM files directly to repository root structure
log "Copying RPM files..."
for platform_dir in "$COPR_DOWNLOAD_DIR"/*/; do
    if [ -d "$platform_dir" ]; then
        platform=$(basename "$platform_dir")
        target_dir="$REPO_OUTPUT_DIR/$(echo "$platform" | tr '-' '/')"

        mkdir -p "$target_dir"
        find "$platform_dir" -name "*.rpm" -exec cp {} "$target_dir/" \;

        rpm_count=$(find "$target_dir" -name "*.rpm" | wc -l)
        log "  $platform: copied $rpm_count RPM files"
    fi
done

total_rpms=$(find "$REPO_OUTPUT_DIR" -path ./.output -prune -o -name "*.rpm" -print | wc -l)

# Summary
success "RPMs merged successfully!"
echo ""
echo "Repository Summary:"
echo "  URL: https://flightctl.github.io/flightctl-rpm/"
echo "  Total packages: $total_rpms"
echo "  Output directory: $REPO_OUTPUT_DIR"
echo "  Latest version: $LATEST_VERSION"
echo ""
echo "Ready for PR to flightctl/flightctl-rpm repository!"
