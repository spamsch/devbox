#!/bin/bash
# =============================================================================
# install-vim-theme.sh - Install vim-theme into a running container
# =============================================================================
#
# Temporary script to add the vim-theme command and vimrc configuration
# to an already-running container without rebuilding the image.
#
# Usage (from host):
#   docker exec -i <container> bash < scripts/install-vim-theme.sh
#
# Or copy and run inside the container:
#   bash install-vim-theme.sh
#
# =============================================================================

set -euo pipefail

BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
DIM=$'\033[2m'
NC=$'\033[0m'

echo "${BOLD}Installing vim-theme...${NC}"

# --- 1. Write the vim-theme script -------------------------------------------

sudo tee /usr/local/bin/vim-theme > /dev/null << 'SCRIPT'
#!/bin/bash
# =============================================================================
# vim-theme - Interactive vim colorscheme switcher
# =============================================================================
#
# Switch vim's colorscheme using an interactive fzf picker.
# The selection is persisted to ~/.vim/theme and loaded on vim startup.
#
# Usage:
#   vim-theme             Interactive colorscheme picker (fzf)
#   vim-theme --list      List all available colorschemes
#   vim-theme --current   Show the currently selected colorscheme
#
# =============================================================================

BOLD=$'\033[1m'
DIM=$'\033[2m'
CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

THEME_FILE="$HOME/.vim/theme"

# Built-in vim colorschemes available in Debian's vim package
THEMES=(
    "default"
    "blue"
    "darkblue"
    "delek"
    "desert"
    "elflord"
    "evening"
    "habamax"
    "industry"
    "koehler"
    "lunaperche"
    "morning"
    "murphy"
    "pablo"
    "peachpuff"
    "quiet"
    "retrobox"
    "ron"
    "shine"
    "slate"
    "sorbet"
    "torte"
    "wildcharm"
    "zazen"
)

get_current_theme() {
    if [[ -f "$THEME_FILE" ]]; then
        sed -n 's/^colorscheme //p' "$THEME_FILE"
    else
        echo "default"
    fi
}

show_current() {
    local current
    current=$(get_current_theme)
    echo "${BOLD}Current vim colorscheme:${NC} ${GREEN}${current}${NC}"
}

list_themes() {
    local current
    current=$(get_current_theme)
    echo "${BOLD}${CYAN}Available vim colorschemes${NC}"
    echo ""
    for theme in "${THEMES[@]}"; do
        if [[ "$theme" == "$current" ]]; then
            echo "  ${GREEN}${theme}${NC} ${DIM}(current)${NC}"
        else
            echo "  ${theme}"
        fi
    done
}

pick_theme() {
    if ! command -v fzf &>/dev/null; then
        echo "Error: fzf is not installed"
        exit 1
    fi

    local current
    current=$(get_current_theme)

    local selected
    selected=$(printf '%s\n' "${THEMES[@]}" | fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt="colorscheme> " \
        --header="Current: ${current} | Enter to select, Esc to cancel")

    if [[ -z "$selected" ]]; then
        echo "${DIM}No theme selected.${NC}"
        return
    fi

    # Ensure ~/.vim directory exists
    mkdir -p "$HOME/.vim"

    # Write the colorscheme command
    echo "colorscheme ${selected}" > "$THEME_FILE"

    echo "${GREEN}✓${NC} Vim colorscheme set to ${BOLD}${selected}${NC}"
    echo "${DIM}  Open vim to see the change.${NC}"
}

case "${1:-}" in
    --list)
        list_themes
        ;;
    --current)
        show_current
        ;;
    --help|-h)
        echo "Usage: vim-theme [--list | --current | --help]"
        echo ""
        echo "  ${BOLD}vim-theme${NC}           Interactive colorscheme picker (fzf)"
        echo "  ${BOLD}vim-theme --list${NC}    List all available colorschemes"
        echo "  ${BOLD}vim-theme --current${NC} Show the currently selected colorscheme"
        ;;
    "")
        pick_theme
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run 'vim-theme --help' for usage."
        exit 1
        ;;
esac
SCRIPT

sudo chmod +x /usr/local/bin/vim-theme
echo "  ${GREEN}✓${NC} /usr/local/bin/vim-theme installed"

# --- 2. Patch ~/.vimrc -------------------------------------------------------

VIMRC="$HOME/.vimrc"
MARKER="Load user-selected colorscheme (set by vim-theme command)"

if [[ -f "$VIMRC" ]] && grep -qF "$MARKER" "$VIMRC"; then
    echo "  ${DIM}~/.vimrc already patched, skipping${NC}"
else
    cat >> "$VIMRC" << 'VIMRC_BLOCK'

" -----------------------------------------------------------------------------
" Colorscheme (user-selected via vim-theme command)
" -----------------------------------------------------------------------------
" Load user-selected colorscheme (set by vim-theme command)
if filereadable(expand("~/.vim/theme"))
    source ~/.vim/theme
endif
VIMRC_BLOCK
    echo "  ${GREEN}✓${NC} ~/.vimrc patched"
fi

# --- Done --------------------------------------------------------------------

echo ""
echo "${GREEN}Done.${NC} Run ${BOLD}vim-theme${NC} to pick a colorscheme."
