#!/bin/bash
# =============================================================================
# Devbox Setup Wizard
# =============================================================================
#
# Interactive setup script for first-time configuration.
# This script helps users configure:
#   1. Git identity (name and email)
#   2. API keys (Anthropic, OpenAI)
#   3. GitHub CLI authentication
#
# Usage:
#   devbox-setup          - Run the full setup wizard
#   devbox-setup --reset  - Reset and re-run setup
#   devbox-setup --help   - Show help
#
# The script saves a marker file when complete to track setup status.
#
# =============================================================================

set -e  # Exit on error

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
DEVBOX_MARKER="$HOME/.devbox-initialized"
ENV_FILE="$HOME/.devbox-env"

# -----------------------------------------------------------------------------
# Color Codes
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'  # No Color

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

print_header() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                    Devbox Setup Wizard                      ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}─── $1 ───${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Read input with a default value
read_with_default() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        printf "%s %b[%s]%b: " "$prompt" "$DIM" "$default" "$NC"
    else
        printf "%s: " "$prompt"
    fi
    
    read -r result
    
    # Return the result (use default if empty)
    if [ -n "$result" ]; then
        printf "%s" "$result"
    else
        printf "%s" "$default"
    fi
}

# Read password/secret (hidden input)
read_secret() {
    local prompt="$1"
    local result
    
    echo -en "${prompt}: "
    read -s result
    echo ""  # New line after hidden input
    echo "$result"
}

# Ask yes/no question
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local result
    
    if [ "$default" = "y" ]; then
        echo -en "${prompt} ${DIM}[Y/n]${NC}: "
    else
        echo -en "${prompt} ${DIM}[y/N]${NC}: "
    fi
    
    read result
    result="${result:-$default}"
    
    case "$result" in
        [Yy]* ) return 0 ;;
        * ) return 1 ;;
    esac
}

# -----------------------------------------------------------------------------
# Setup Functions
# -----------------------------------------------------------------------------

# Setup Git identity
setup_git() {
    print_section "Git Configuration"
    
    # Get current values (if any)
    local current_name=$(git config --global user.name 2>/dev/null || echo "")
    local current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    # Filter out placeholder defaults
    [ "$current_name" = "Developer" ] && current_name=""
    [ "$current_email" = "dev@devbox" ] && current_email=""
    
    # Show current status
    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        print_info "Current git identity: $current_name <$current_email>"
        echo ""
        if ! ask_yes_no "Update git configuration?" "n"; then
            print_success "Keeping existing git configuration"
            return 0
        fi
    else
        print_info "No git identity configured yet."
    fi
    
    echo ""
    
    # Get name
    local name
    if [ -n "$current_name" ]; then
        printf "  ${BOLD}Name${NC} ${DIM}[%s]${NC}: " "$current_name"
    else
        printf "  ${BOLD}Name${NC}: "
    fi
    read -r name
    name="${name:-$current_name}"
    if [ -n "$name" ]; then
        git config --global user.name "$name"
        print_success "Name set to: $name"
    fi
    
    # Get email
    local email
    if [ -n "$current_email" ]; then
        printf "  ${BOLD}Email${NC} ${DIM}[%s]${NC}: " "$current_email"
    else
        printf "  ${BOLD}Email${NC}: "
    fi
    read -r email
    email="${email:-$current_email}"
    if [ -n "$email" ]; then
        git config --global user.email "$email"
        print_success "Email set to: $email"
    fi
    
    # Set recommended git defaults
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    
    print_success "Git configuration complete"
}

# Setup API keys
setup_api_keys() {
    print_section "API Keys (Optional)"
    
    print_info "API keys are used by OpenCode for AI assistance."
    echo ""
    echo -e "  ${BOLD}You have several options:${NC}"
    echo ""
    echo -e "  ${CYAN}1. Free models${NC}"
    echo "     OpenCode includes free models - just run 'opencode'."
    echo ""
    echo -e "  ${CYAN}2. Claude Pro/Max (recommended)${NC}"
    echo "     Use your existing Anthropic subscription:"
    echo "     - Run 'opencode' and type: /connect"
    echo "     - Select 'Anthropic' then 'Claude Pro/Max'"
    echo "     - Authenticate via browser when prompted"
    echo ""
    echo -e "  ${CYAN}3. API Key${NC}"
    echo "     Set ANTHROPIC_API_KEY or OPENAI_API_KEY environment variable."
    echo ""
    echo -e "  ${DIM}OpenCode supports 75+ providers. See https://opencode.ai/docs/providers${NC}"
    echo ""
    
    if ! ask_yes_no "Configure API key now? (You can skip and use free models or /connect later)" "n"; then
        print_info "Skipping API key configuration"
        print_info "Run 'opencode' to start - use free models or type /connect to add a provider"
        return 0
    fi
    
    echo ""
    
    # Create or update env file
    touch "$ENV_FILE"
    
    # Anthropic API key
    echo -e "  ${BOLD}Anthropic API Key${NC} (for Claude models)"
    echo -e "  ${DIM}Get yours at: https://console.anthropic.com/settings/keys${NC}"
    local anthropic_key=$(read_secret "  ANTHROPIC_API_KEY (leave empty to skip)")
    
    if [ -n "$anthropic_key" ]; then
        # Update or add the key in env file
        if grep -q "^ANTHROPIC_API_KEY=" "$ENV_FILE" 2>/dev/null; then
            sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$anthropic_key|" "$ENV_FILE"
        else
            echo "ANTHROPIC_API_KEY=$anthropic_key" >> "$ENV_FILE"
        fi
        print_success "Anthropic API key saved"
        export ANTHROPIC_API_KEY="$anthropic_key"
    else
        print_info "Skipped Anthropic API key"
    fi
    
    echo ""
    
    # OpenAI API key (optional, for alternative models)
    echo -e "  ${BOLD}OpenAI API Key${NC} (optional, for GPT models)"
    echo -e "  ${DIM}Get yours at: https://platform.openai.com/api-keys${NC}"
    local openai_key=$(read_secret "  OPENAI_API_KEY (leave empty to skip)")
    
    if [ -n "$openai_key" ]; then
        if grep -q "^OPENAI_API_KEY=" "$ENV_FILE" 2>/dev/null; then
            sed -i "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=$openai_key|" "$ENV_FILE"
        else
            echo "OPENAI_API_KEY=$openai_key" >> "$ENV_FILE"
        fi
        print_success "OpenAI API key saved"
        export OPENAI_API_KEY="$openai_key"
    else
        print_info "Skipped OpenAI API key"
    fi
    
    # Set permissions on env file
    chmod 600 "$ENV_FILE"
    
    echo ""
    print_success "API key configuration complete"
    print_info "Keys are stored in ~/.devbox-env and loaded automatically"
}

# Setup GitHub CLI
setup_github() {
    print_section "GitHub CLI Authentication (Optional)"
    
    # Check if already authenticated
    if gh auth status &>/dev/null; then
        local gh_user=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
        print_success "Already authenticated as: $gh_user"
        echo ""
        if ! ask_yes_no "Re-authenticate with GitHub?" "n"; then
            return 0
        fi
    else
        print_info "GitHub CLI (gh) allows you to:"
        echo "    - Clone private repositories"
        echo "    - Create pull requests"
        echo "    - Manage issues"
        echo "    - And more..."
        echo ""
    fi
    
    if ask_yes_no "Authenticate with GitHub now?" "y"; then
        echo ""
        print_info "Starting GitHub authentication..."
        print_info "Follow the prompts below:"
        echo ""
        
        # Run gh auth login interactively
        if gh auth login; then
            print_success "GitHub authentication complete"
        else
            print_warning "GitHub authentication was not completed"
            print_info "Run 'gh auth login' later to authenticate"
        fi
    else
        print_info "Skipping GitHub authentication"
        print_info "Run 'gh auth login' later to authenticate"
    fi
}

# Mark setup as complete
mark_complete() {
    # Save completion marker with timestamp
    echo "# Devbox setup completed" > "$DEVBOX_MARKER"
    echo "SETUP_DATE=$(date -Iseconds)" >> "$DEVBOX_MARKER"
    echo "SETUP_VERSION=1.0.0" >> "$DEVBOX_MARKER"
}

# Show completion message
show_complete() {
    print_section "Setup Complete!"
    
    echo -e "  Your development environment is ready."
    echo ""
    echo -e "  ${BOLD}Quick Start:${NC}"
    echo -e "    ${CYAN}opencode${NC}          - Start OpenCode (AI-assisted coding)"
    echo -e "    ${CYAN}tmux-dev${NC}          - Start tmux with 3-pane dev layout"
    echo -e "    ${CYAN}gh repo clone${NC}     - Clone a GitHub repository"
    echo ""
    echo -e "  ${BOLD}Useful Commands:${NC}"
    echo -e "    ${CYAN}devbox-setup${NC}      - Re-run this setup wizard"
    echo -e "    ${CYAN}uv pip install${NC}    - Install Python packages"
    echo -e "    ${CYAN}npm install${NC}       - Install Node.js packages"
    echo ""
    echo -e "  ${BOLD}Keyboard Shortcuts:${NC}"
    echo -e "    ${CYAN}Ctrl+R${NC}            - Search command history (fzf)"
    echo -e "    ${CYAN}Ctrl+T${NC}            - Find files (fzf)"
    echo -e "    ${CYAN}Alt+C${NC}             - Change directory (fzf)"
    echo ""
    
    print_success "Happy coding!"
    echo ""
}

# Show help
show_help() {
    echo "Devbox Setup Wizard"
    echo ""
    echo "Usage: devbox-setup [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help     Show this help message"
    echo "  --reset    Reset setup and run wizard again"
    echo "  --status   Show current setup status"
    echo ""
    echo "The setup wizard helps you configure:"
    echo "  - Git identity (name and email)"
    echo "  - API keys (Anthropic, OpenAI)"
    echo "  - GitHub CLI authentication"
    echo ""
}

# Show status
show_status() {
    echo "Devbox Setup Status"
    echo "==================="
    echo ""
    
    # Check marker file
    if [ -f "$DEVBOX_MARKER" ]; then
        print_success "Setup completed"
        source "$DEVBOX_MARKER"
        echo "  Date: ${SETUP_DATE:-unknown}"
        echo "  Version: ${SETUP_VERSION:-unknown}"
    else
        print_warning "Setup not completed"
        echo "  Run 'devbox-setup' to configure"
    fi
    
    echo ""
    
    # Git status
    echo "Git Configuration:"
    local git_name=$(git config --global user.name 2>/dev/null || echo "not set")
    local git_email=$(git config --global user.email 2>/dev/null || echo "not set")
    echo "  Name: $git_name"
    echo "  Email: $git_email"
    
    echo ""
    
    # API keys status
    echo "API Keys:"
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        print_success "ANTHROPIC_API_KEY is set"
    else
        print_warning "ANTHROPIC_API_KEY not set"
    fi
    if [ -n "$OPENAI_API_KEY" ]; then
        print_success "OPENAI_API_KEY is set"
    else
        print_info "OPENAI_API_KEY not set (optional)"
    fi
    
    echo ""
    
    # GitHub CLI status
    echo "GitHub CLI:"
    if gh auth status &>/dev/null; then
        local gh_user=$(gh api user --jq '.login' 2>/dev/null || echo "authenticated")
        print_success "Authenticated as: $gh_user"
    else
        print_warning "Not authenticated"
        echo "  Run 'gh auth login' to authenticate"
    fi
    
    echo ""
}

# Reset setup
reset_setup() {
    print_warning "This will reset your Devbox setup."
    echo "  Your API keys and git config will be preserved."
    echo "  The setup wizard will run again on next start."
    echo ""
    
    if ask_yes_no "Continue with reset?" "n"; then
        rm -f "$DEVBOX_MARKER"
        print_success "Setup reset complete"
        print_info "Run 'devbox-setup' to configure again"
    else
        print_info "Reset cancelled"
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    # Parse arguments
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --status|-s)
            show_status
            exit 0
            ;;
        --reset|-r)
            reset_setup
            exit 0
            ;;
    esac
    
    # Load existing env file if present
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    fi
    
    # Run setup wizard
    print_header
    
    echo -e "  This wizard will help you configure your development environment."
    echo -e "  You can re-run it anytime with: ${BOLD}devbox-setup${NC}"
    echo ""
    echo -e "  Press ${BOLD}Enter${NC} to accept defaults shown in ${DIM}[brackets]${NC}."
    echo ""
    
    if ! ask_yes_no "Ready to begin?" "y"; then
        echo ""
        print_info "Setup cancelled. Run 'devbox-setup' when ready."
        exit 0
    fi
    
    # Run setup steps
    setup_git
    setup_api_keys
    setup_github
    
    # Mark as complete
    mark_complete
    
    # Show completion message
    show_complete
}

# Run main function
main "$@"
