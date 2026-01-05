# Devbox - Development Container for OpenCode with Python & JavaScript

## Overview

A Docker-based development environment optimized for AI-assisted coding with OpenCode. The container provides a ready-to-use environment for Python and JavaScript development with minimal setup friction.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Base Image** | Debian Bookworm | Stable, well-tested, good package availability |
| **Container Strategy** | One per project | Better isolation, no conflicts between projects |
| **Container Name** | `devbox` | Short, memorable, describes purpose |
| **Starship Preset** | No Nerd Fonts | Works in any terminal without special fonts |

## Goals

1. **Instant Productivity**: Connect to container, run one setup script, start coding
2. **Minimal Configuration**: Sensible defaults that work out of the box
3. **Persistent State**: Preserve authentication, history, and preferences across sessions
4. **Language Support**: First-class support for Python (uv) and JavaScript (nvm/npm)
5. **Modern Shell Experience**: zsh with starship prompt and tmux for session management
6. **AI-First Design**: Optimized for OpenCode and agentic workflows

---

## Core Components

### Required Tools

| Tool | Purpose | Installation Method |
|------|---------|---------------------|
| **OpenCode** | AI coding assistant | npm (global) |
| **Python/uv** | Python development | astral.sh installer |
| **Node.js/npm** | JavaScript development | nvm |
| **tmux** | Terminal multiplexer | apt |
| **zsh** | Shell | apt |
| **Starship** | Cross-shell prompt | Official installer |
| **git** | Version control | apt |

### Supporting Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| `gh` | GitHub CLI for repository operations | GitHub apt repo |
| `ripgrep` | Fast code search | apt |
| `fd` | Fast file finder | apt (`fd-find`) |
| `fzf` | Fuzzy finder for files and history | apt |
| `jq` | JSON processing | apt |
| `direnv` | Directory-specific environment variables | apt |
| `htop` | Process monitoring | apt |
| `vim` | Text editor | apt (with sensible config) |

---

## Architecture

### Container Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Container (devbox)                 │
├─────────────────────────────────────────────────────────────┤
│  Base: Debian Bookworm (stable)                             │
├─────────────────────────────────────────────────────────────┤
│  Shell Layer:                                                │
│  ├── zsh + oh-my-zsh                                        │
│  ├── starship prompt (no-nerd-font preset)                  │
│  ├── tmux with sensible config                              │
│  ├── fzf integration (Ctrl+R history, Ctrl+T files)         │
│  └── vim with sensible defaults                             │
├─────────────────────────────────────────────────────────────┤
│  Language Runtimes:                                          │
│  ├── Python via uv (latest stable)                          │
│  └── Node.js via nvm (LTS)                                  │
├─────────────────────────────────────────────────────────────┤
│  AI Tools:                                                   │
│  └── OpenCode (npm global install)                          │
├─────────────────────────────────────────────────────────────┤
│  Dev Tools:                                                  │
│  ├── git, gh, ripgrep, fd, fzf, jq, direnv                  │
│  ├── htop, vim, curl, wget                                  │
│  └── build-essential (for native packages)                  │
└─────────────────────────────────────────────────────────────┘
```

### Per-Project Isolation

Each project gets its own container instance named `devbox-<project-hash>`:

```
Project: ~/code/my-app
  └── Container: devbox-a1b2c3d4
      ├── Image: devbox:latest (shared)
      ├── Volume: devbox-data-a1b2c3d4 (project-specific)
      └── Mount: ~/code/my-app -> /workspace

Project: ~/code/other-project  
  └── Container: devbox-e5f6g7h8
      ├── Image: devbox:latest (shared)
      ├── Volume: devbox-data-e5f6g7h8 (project-specific)
      └── Mount: ~/code/other-project -> /workspace
```

**Benefits:**
- No package conflicts between projects
- Each project has its own shell history
- Can run multiple projects simultaneously
- Shared base image saves disk space

### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `$(pwd)` | `/workspace` | Project directory |
| `~/.devbox/<hash>/config` | `/home/dev/.config` | Tool configurations |
| `~/.devbox/<hash>/cache` | `/home/dev/.cache` | Package caches (npm, uv) |
| `~/.devbox/<hash>/data` | `/home/dev/.local/share` | Persistent app data |
| `~/.devbox/shared/history` | `/home/dev/.zsh_history` | Shell history (shared) |
| `~/.ssh` (read-only) | `/home/dev/.ssh` | SSH keys for git |
| `~/.gitconfig` (read-only) | `/tmp/host_gitconfig` | Git config import |

### Data Persistence Strategy

Following the patterns from AgentBox and ClaudeBox:

1. **Ephemeral Container**: Container itself is disposable (`--rm`)
2. **Persistent Volumes**: Important data survives container restarts:
   - Authentication tokens
   - Shell history
   - Package caches
   - Tool configurations

---

## Setup Flow

### First-Time Setup (Interactive Script)

When user connects to the container for the first time:

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│   Welcome to Devbox!                                       │
│                                                            │
│   First-time setup detected. Let's configure your         │
│   environment.                                             │
│                                                            │
│   ─────────────────────────────────────────────────────   │
│                                                            │
│   1. Git Configuration                                     │
│      > Enter your name: [pre-filled from host if avail]   │
│      > Enter your email: [pre-filled from host if avail]  │
│                                                            │
│   2. API Keys (optional - can set later)                   │
│      > ANTHROPIC_API_KEY: [hidden input]                  │
│      > OPENAI_API_KEY: [hidden input]                     │
│                                                            │
│   3. GitHub Authentication                                 │
│      > Run 'gh auth login' now? [Y/n]                     │
│                                                            │
│   Setup complete! Run 'claude' to start coding.         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### Setup Script Requirements

1. **Detect First Run**: Check for marker file (e.g., `~/.devbox-initialized`)
2. **Pre-fill from Host**: Import git config, SSH keys from mounted volumes
3. **Secure Storage**: API keys stored in persistent volume
4. **Idempotent**: Safe to run multiple times
5. **Skip Option**: Allow skipping with `--skip-setup` or `SKIP_SETUP=1`
6. **Re-run Option**: Can be triggered manually with `devbox-setup`

### Automatic Behavior

The setup script runs automatically on first connection. Subsequent connections show a brief welcome message:

```
┌────────────────────────────────────────────────────────────┐
│  Devbox - Python & JavaScript Development Environment      │
│  Project: /workspace (my-app)                              │
│  Run 'claude' to start coding or 'devbox-setup' to      │
│  reconfigure.                                              │
└────────────────────────────────────────────────────────────┘
```

---

## Configuration Defaults

### Starship Prompt (No Nerd Font Preset)

Using the official "No Nerd Font" preset which works in any terminal without special fonts installed.

```toml
# ~/.config/starship.toml
# Based on: starship preset no-nerd-font

"$schema" = 'https://starship.rs/config-schema.json'

[battery]
full_symbol = "• "
charging_symbol = "⇡ "
discharging_symbol = "⇣ "
unknown_symbol = "❓ "
empty_symbol = "❗ "

[erlang]
symbol = "ⓔ "

[fortran]
symbol = "F "

[nodejs]
symbol = "[⬢](bold green) "

[pulumi]
symbol = "🧊 "

[typst]
symbol = "t "
```

The preset ensures all symbols use emoji or standard Unicode characters that render correctly in any terminal.

### tmux Configuration

```bash
# ~/.tmux.conf - Sensible defaults for development

# Modern terminal support
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

# Enable mouse support (scrolling, pane selection, resizing)
set -g mouse on

# Increase scrollback history
set -g history-limit 50000

# Start window/pane numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Easy pane splitting (keep current path)
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Easy pane navigation (vim-style)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Quick reload config
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Minimal status bar
set -g status-style bg=default,fg=white
set -g status-left "#[fg=green][#S] "
set -g status-right "#[fg=cyan]%H:%M"
set -g status-left-length 20

# Reduce escape time for vim
set -sg escape-time 10

# Enable focus events for vim autoread
set -g focus-events on
```

### vim Configuration

```vim
" ~/.vimrc - Sensible defaults

" Modern defaults
set nocompatible
filetype plugin indent on
syntax enable

" UI improvements
set number                  " Show line numbers
set relativenumber          " Relative line numbers
set cursorline              " Highlight current line
set showmatch               " Highlight matching brackets
set wildmenu                " Better command completion
set laststatus=2            " Always show status line

" Search
set hlsearch                " Highlight search results
set incsearch               " Incremental search
set ignorecase              " Case insensitive search
set smartcase               " Unless uppercase used

" Indentation
set expandtab               " Spaces instead of tabs
set tabstop=4               " 4 spaces per tab
set shiftwidth=4            " 4 spaces for indent
set autoindent              " Copy indent from current line
set smartindent             " Smart autoindenting

" Quality of life
set backspace=indent,eol,start  " Backspace works as expected
set hidden                  " Allow hidden buffers
set autoread                " Auto-reload changed files
set clipboard=unnamedplus   " Use system clipboard
set mouse=a                 " Enable mouse support

" Performance
set lazyredraw              " Don't redraw during macros
set updatetime=300          " Faster completion

" File handling
set nobackup
set nowritebackup
set noswapfile
set undofile                " Persistent undo
set undodir=~/.vim/undodir
```

### zsh Configuration

```bash
# ~/.zshrc

# Oh-my-zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Disabled - using starship instead

# Minimal, useful plugins
plugins=(
    git              # Git aliases and functions
    direnv           # Auto-load .envrc files
    z                # Jump to frequently used directories
    fzf              # Fuzzy finder integration
    zsh-autosuggestions      # Fish-like suggestions
    zsh-syntax-highlighting  # Command highlighting
)

source $ZSH/oh-my-zsh.sh

# Initialize starship prompt
eval "$(starship init zsh)"

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -20'

# PATH additions
export PATH="$HOME/.local/bin:$PATH"
```

### fzf Integration

fzf provides powerful fuzzy finding capabilities:

| Keybinding | Action |
|------------|--------|
| `Ctrl+R` | Search command history |
| `Ctrl+T` | Search files in current directory |
| `Alt+C` | Change to subdirectory |
| `**<Tab>` | Fuzzy completion (e.g., `vim **<Tab>`) |

### gh (GitHub CLI) Configuration

```yaml
# ~/.config/gh/config.yml
git_protocol: ssh
editor: vim
prompt: enabled
aliases:
    co: pr checkout
    pv: pr view
    pc: pr create
```

---

## Launcher Script (Host-Side)

A simple bash script to launch the container:

```bash
#!/bin/bash
# devbox - Launch development container

# Usage: devbox [command]
#   devbox              - Start interactive shell
#   devbox shell        - Start shell (same as above)
#   devbox claude     - Start opencode directly
#   devbox exec <cmd>   - Run command in container
#   devbox --rebuild    - Force rebuild image
#   devbox --clean      - Remove project container/data
#   devbox --info       - Show project/container info
```

### Key Features

1. **Auto-detect UID/GID**: Match host user to avoid permission issues
2. **Project Hash**: Generate unique container name from project path
3. **Smart Volume Mounting**: Only mount what exists
4. **Environment Forwarding**: Pass through `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, etc.
5. **TTY Handling**: Proper terminal allocation
6. **Rebuild Detection**: Auto-rebuild when Dockerfile changes

### Container Naming Convention

```bash
# Container name derived from project path
PROJECT_HASH=$(echo "$PWD" | md5sum | cut -c1-8)
CONTAINER_NAME="devbox-${PROJECT_HASH}"

# Example:
# ~/code/my-app -> devbox-a1b2c3d4
# ~/code/other  -> devbox-e5f6g7h8
```

---

## Comparison with Reference Projects

### From AgentBox (fletchgqc/agentbox)

**Adopted Ideas:**
- Simple 3-file architecture (Dockerfile, entrypoint.sh, launcher script)
- Unified single image vs. multiple profiles
- Auto-rebuild detection
- direnv support with host approval translation
- Host gitconfig mounting

**Differences:**
- AgentBox focuses on OpenCode; we focus on OpenCode
- AgentBox includes Java/SDKMAN; we focus on Python/JS only
- We add starship prompt; AgentBox uses oh-my-zsh themes

### From ClaudeBox (RchGrav/claudebox)

**Adopted Ideas:**
- Profile system concept (but simplified)
- Firewall/network isolation options
- Per-project isolation model
- Comprehensive info command

**Differences:**
- ClaudeBox is complex (20+ files); we aim for simplicity
- ClaudeBox has many profiles; we have one unified image
- ClaudeBox has slot system; we use simpler per-directory approach

---

## Security Considerations

### Default Security Posture

1. **Non-root User**: Container runs as non-root `dev` user
2. **Sudo Available**: For package installation when needed
3. **Read-only SSH**: Host SSH keys mounted read-only
4. **No Privileged Mode**: Standard container isolation

### API Key Handling

1. **Never in Dockerfile**: API keys passed at runtime only
2. **Environment Variables**: Preferred method for keys
3. **Optional Persistence**: Encrypted storage for convenience
4. **.env Support**: Load from project `.env` file

---

## File Structure

```
docker-for-agentic-dev/
├── Dockerfile              # Container image definition
├── entrypoint.sh           # Container initialization script
├── devbox                  # Host-side launcher script (symlink to PATH)
├── config/
│   ├── starship.toml       # Starship prompt config (no-nerd-font preset)
│   ├── tmux.conf           # tmux configuration
│   ├── vimrc               # vim configuration
│   └── zshrc               # zsh configuration
├── scripts/
│   └── setup.sh            # First-time setup wizard
├── REQUIREMENTS.md         # This document
└── README.md               # User documentation
```

---

## Implementation Phases

### Phase 1: Core Container
- [ ] Dockerfile with base system
- [ ] Python/uv installation
- [ ] Node.js/nvm installation
- [ ] OpenCode installation
- [ ] Basic entrypoint

### Phase 2: Shell Experience
- [ ] zsh + oh-my-zsh
- [ ] Starship prompt
- [ ] tmux configuration
- [ ] Shell history persistence

### Phase 3: Setup Wizard
- [ ] First-run detection
- [ ] Interactive configuration
- [ ] Git identity setup
- [ ] API key management
- [ ] GitHub CLI auth

### Phase 4: Launcher Script
- [ ] devbox launcher
- [ ] Volume mount logic
- [ ] UID/GID mapping
- [ ] Rebuild detection

### Phase 5: Polish
- [ ] Documentation
- [ ] Example configurations
- [ ] Troubleshooting guide

---

## Resolved Decisions

| Question | Decision | Notes |
|----------|----------|-------|
| Base Image | Debian Bookworm | Stable, well-tested |
| Multi-project | One container per project | Better isolation |
| Container name | `devbox` | Short and clear |
| Starship preset | No Nerd Font | Universal terminal support |

## Remaining Open Questions

1. **OpenCode Installation**: npm global vs local?
   - **Recommendation**: Global install for simplicity

2. **Configuration Format**: Where to store user preferences?
   - **Recommendation**: Multiple config files (current approach) - familiar to users

3. **Auto-update Strategy**: How to keep tools current?
   - **Recommendation**: Rebuild container with `devbox --rebuild`

---

## Success Criteria

1. **Time to First Prompt**: < 30 seconds from `docker run` to working shell
2. **Time to First OpenCode Session**: < 2 minutes including first-time setup
3. **Rebuild Time**: < 5 minutes for full image rebuild (with cache)
4. **Disk Usage**: < 2GB for base image
5. **Zero Config Possible**: Should work with defaults for common cases
