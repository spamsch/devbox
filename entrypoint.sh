#!/bin/bash
# =============================================================================
# Devbox Entrypoint Script
# =============================================================================
#
# This script runs when the container starts. It handles:
#   1. Environment setup (PATH, NVM, etc.)
#   2. Git configuration from host
#   3. SSH key permissions
#   4. First-run detection and setup wizard
#   5. Welcome message display
#
# The script is designed to be fast and non-intrusive on subsequent runs.
#
# =============================================================================

set -e  # Exit on error

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
DEVBOX_MARKER="$HOME/.devbox-initialized"
DEVBOX_VERSION="1.0.0"

# -----------------------------------------------------------------------------
# Color Codes (for terminal output)
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No Color

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Print a colored message
log_info() {
    echo -e "${BLUE}[info]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[ok]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[warn]${NC} $1"
}

log_error() {
    echo -e "${RED}[error]${NC} $1"
}

# -----------------------------------------------------------------------------
# Environment Setup
# -----------------------------------------------------------------------------
# Ensure PATH includes user binaries
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# Source NVM if available
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
fi

# Set terminal for better experience
export TERM="${TERM:-xterm-256color}"

# -----------------------------------------------------------------------------
# Default Configuration Files
# -----------------------------------------------------------------------------
# Copy default config files if they don't exist in the mounted volume.
# This ensures the starship preset and other configs are available.
# -----------------------------------------------------------------------------
setup_default_configs() {
    # Starship config
    if [ ! -f "$HOME/.config/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        cp /etc/devbox/defaults/starship.toml "$HOME/.config/starship.toml" 2>/dev/null || true
    fi
    
    # tmux layout config
    if [ ! -f "$HOME/.tmux/dev-layout.conf" ]; then
        mkdir -p "$HOME/.tmux"
        cp /etc/devbox/defaults/tmux/dev-layout.conf "$HOME/.tmux/dev-layout.conf" 2>/dev/null || true
    fi
    
    # vim undo directory
    mkdir -p "$HOME/.vim/undodir"
}

# -----------------------------------------------------------------------------
# Git Configuration
# -----------------------------------------------------------------------------
# Import git configuration from host if available.
# The host's .gitconfig is mounted at /tmp/host_gitconfig by the launcher.
# -----------------------------------------------------------------------------
setup_git_config() {
    if [ -f "/tmp/host_gitconfig" ]; then
        # Copy host gitconfig to user's home
        cp /tmp/host_gitconfig "$HOME/.gitconfig" 2>/dev/null || true
    fi
    
    # Ensure basic git config exists (fallback defaults)
    if ! git config --global user.name &>/dev/null; then
        git config --global user.name "Developer"
    fi
    if ! git config --global user.email &>/dev/null; then
        git config --global user.email "dev@devbox"
    fi
    
    # Set sensible git defaults
    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global pull.rebase false 2>/dev/null || true
    git config --global core.autocrlf input 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# SSH Key Permissions
# -----------------------------------------------------------------------------
# Fix permissions on SSH keys if mounted from host.
# SSH is very strict about permissions on key files.
# -----------------------------------------------------------------------------
setup_ssh_permissions() {
    if [ -d "$HOME/.ssh" ]; then
        chmod 700 "$HOME/.ssh" 2>/dev/null || true
        chmod 600 "$HOME/.ssh/"* 2>/dev/null || true
        chmod 644 "$HOME/.ssh/"*.pub 2>/dev/null || true
        chmod 644 "$HOME/.ssh/known_hosts" 2>/dev/null || true
        chmod 644 "$HOME/.ssh/authorized_keys" 2>/dev/null || true
        chmod 644 "$HOME/.ssh/config" 2>/dev/null || true
    fi
}

# -----------------------------------------------------------------------------
# Python Virtual Environment
# -----------------------------------------------------------------------------
# Create a Python virtual environment if the project has Python files
# but no existing venv.
# -----------------------------------------------------------------------------
setup_python_venv() {
    local workspace="/workspace"
    
    # Check if this looks like a Python project
    if [ -f "$workspace/requirements.txt" ] || \
       [ -f "$workspace/pyproject.toml" ] || \
       [ -f "$workspace/setup.py" ] || \
       [ -f "$workspace/setup.cfg" ]; then
        
        # Create venv if it doesn't exist
        if [ ! -d "$workspace/.venv" ]; then
            log_info "Python project detected, creating virtual environment..."
            cd "$workspace"
            uv venv .venv 2>/dev/null || python3 -m venv .venv
            log_success "Virtual environment created at .venv/"
            echo "         Activate with: source .venv/bin/activate"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Direnv Setup
# -----------------------------------------------------------------------------
# Translate host direnv approvals to container paths.
# This allows .envrc files approved on the host to work in the container.
# -----------------------------------------------------------------------------
setup_direnv() {
    # Check if direnv allowlist was mounted from host
    if [ -d "/tmp/host_direnv_allow" ] && [ -f "/workspace/.envrc" ] && [ -n "$HOST_PROJECT_DIR" ]; then
        mkdir -p "$HOME/.local/share/direnv/allow"
        
        # Calculate hash for host path
        local host_envrc_path="$HOST_PROJECT_DIR/.envrc"
        local expected_host_hash=$(printf "%s\n" "$host_envrc_path" | cat - /workspace/.envrc | sha256sum | cut -d' ' -f1)
        
        # If valid approval exists, create container approval
        if [ -f "/tmp/host_direnv_allow/$expected_host_hash" ]; then
            local approved_path=$(cat "/tmp/host_direnv_allow/$expected_host_hash")
            if [ "$approved_path" = "$host_envrc_path" ]; then
                local container_hash=$(printf "/workspace/.envrc\n" | cat - /workspace/.envrc | sha256sum | cut -d' ' -f1)
                echo "/workspace/.envrc" > "$HOME/.local/share/direnv/allow/$container_hash"
            fi
        fi
    fi
}

# -----------------------------------------------------------------------------
# First Run Detection
# -----------------------------------------------------------------------------
# Check if this is the first time running the container for this project.
# If so, run the setup wizard.
# -----------------------------------------------------------------------------
check_first_run() {
    if [ ! -f "$DEVBOX_MARKER" ]; then
        return 0  # First run
    else
        return 1  # Not first run
    fi
}

# -----------------------------------------------------------------------------
# Welcome Message
# -----------------------------------------------------------------------------
# Display a welcome message with useful information.
# Different messages for first run vs. subsequent runs.
# -----------------------------------------------------------------------------
show_welcome() {
    local is_first_run=$1
    local project_name=$(basename "/workspace" 2>/dev/null || echo "workspace")
    
    # Get version info
    local node_version=$(node --version 2>/dev/null || echo "not found")
    local python_version=$(python3 --version 2>&1 | cut -d' ' -f2 || echo "not found")
    local opencode_version=$(opencode --version 2>/dev/null || echo "not found")
    
    echo ""
    echo -e "${BOLD}${CYAN}Devbox${NC} - Development Environment"
    echo -e "────────────────────────────────────────────────────"
    echo -e "  ${BOLD}Project:${NC}    /workspace"
    echo -e "  ${BOLD}Python:${NC}     $python_version (uv available)"
    echo -e "  ${BOLD}Node.js:${NC}    $node_version"
    echo -e "  ${BOLD}OpenCode:${NC}   $opencode_version"
    echo -e "────────────────────────────────────────────────────"
    
    if [ "$is_first_run" = "true" ]; then
        echo ""
        echo -e "  ${YELLOW}First time setup!${NC}"
        echo -e "  Run ${BOLD}devbox-setup${NC} to configure git and GitHub CLI."
        echo -e "  Run ${BOLD}opencode${NC} to start coding."
        echo ""
    else
        echo ""
        echo -e "  Run ${BOLD}opencode${NC} to start coding or ${BOLD}devbox-setup${NC} to reconfigure."
        echo ""
    fi
}

# -----------------------------------------------------------------------------
# Main Initialization
# -----------------------------------------------------------------------------
main() {
    # Run setup tasks (fast, idempotent)
    setup_default_configs
    setup_git_config
    setup_ssh_permissions
    setup_direnv
    
    # Check if interactive terminal
    if [ -t 0 ] && [ -t 1 ]; then
        # Check for first run
        if check_first_run; then
            show_welcome "true"
            # Create marker file to indicate setup is available but not completed
            # The actual marker is created by devbox-setup when completed
        else
            show_welcome "false"
        fi
        
        # Setup Python venv (only for interactive sessions to avoid slowing down commands)
        setup_python_venv
    fi
}

# -----------------------------------------------------------------------------
# Run Initialization
# -----------------------------------------------------------------------------
main

# -----------------------------------------------------------------------------
# Execute Command
# -----------------------------------------------------------------------------
# Execute the command passed to the container (default: /bin/zsh)
exec "$@"
