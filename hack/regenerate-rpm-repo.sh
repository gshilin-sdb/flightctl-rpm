#!/usr/bin/env bash

# Regenerates RPM repositories

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

log "Regenerating RPM repository metadata"

# Find all directories containing RPMs and regenerate their metadata
repos=$(find . -path "./.output" -prune -o -type f -name "*.rpm" -exec dirname {} \; | sort -u)
for repo in $repos; do
    log "Processing repo: $repo"
    createrepo_c "$repo"
done

success "RPM repository metadata regenerated successfully!"
