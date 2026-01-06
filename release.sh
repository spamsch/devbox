#!/bin/bash
# =============================================================================
# Release script for Devbox
# =============================================================================
#
# Usage:
#   ./release.sh patch    # 1.0.0 -> 1.0.1
#   ./release.sh minor    # 1.0.0 -> 1.1.0
#   ./release.sh major    # 1.0.0 -> 2.0.0
#   ./release.sh 1.2.3    # Set specific version
#
# This script:
#   1. Updates VERSION file
#   2. Commits the change
#   3. Creates a git tag
#   4. Pushes to origin (main and release branches)
#   5. GitHub Action builds and pushes Docker image
#
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BOLD}[release]${NC} $1"; }
log_success() { echo -e "${GREEN}[release]${NC} $1"; }
log_error() { echo -e "${RED}[release]${NC} $1" >&2; }

# Get current version
get_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE" | tr -d '[:space:]'
    else
        echo "0.0.0"
    fi
}

# Increment version
increment_version() {
    local version=$1
    local part=$2
    
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    
    case "$part" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Validate version format
validate_version() {
    if [[ ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $1"
        log_error "Expected format: X.Y.Z (e.g., 1.2.3)"
        exit 1
    fi
}

# Main
main() {
    local bump_type="${1:-}"
    
    if [ -z "$bump_type" ]; then
        echo "Usage: $0 <patch|minor|major|X.Y.Z>"
        echo ""
        echo "Current version: $(get_version)"
        exit 1
    fi
    
    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --staged --quiet; then
        log_error "You have uncommitted changes. Please commit or stash them first."
        exit 1
    fi
    
    local current_version=$(get_version)
    local new_version
    
    case "$bump_type" in
        patch|minor|major)
            new_version=$(increment_version "$current_version" "$bump_type")
            ;;
        *)
            validate_version "$bump_type"
            new_version="$bump_type"
            ;;
    esac
    
    log_info "Current version: $current_version"
    log_info "New version: $new_version"
    echo ""
    
    read -p "Continue with release v$new_version? [y/N] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        exit 0
    fi
    
    # Update VERSION file
    log_info "Updating VERSION file..."
    echo "$new_version" > "$VERSION_FILE"
    
    # Commit
    log_info "Committing version bump..."
    git add "$VERSION_FILE"
    git commit -m "Release v$new_version"
    
    # Create tag
    log_info "Creating tag v$new_version..."
    git tag -a "v$new_version" -m "Release v$new_version"
    
    # Push to main
    log_info "Pushing to main..."
    git push origin main
    git push origin "v$new_version"
    
    # Update release branch
    log_info "Updating release branch..."
    if git show-ref --verify --quiet refs/heads/release; then
        git checkout release
        git merge main --no-edit
    else
        git checkout -b release
    fi
    git push -u origin release
    
    # Back to main
    git checkout main
    
    log_success "Released v$new_version"
    echo ""
    echo "GitHub Action will now build and push the Docker image."
    echo "Check: https://github.com/spamsch/devbox/actions"
}

main "$@"
