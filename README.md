# Devbox

A Docker-based development environment for AI-assisted coding with [OpenCode](https://opencode.ai/).

## Quick Start

```bash
# Install
git clone https://github.com/spamsch/devbox.git ~/.devbox-source
ln -s ~/.devbox-source/devbox ~/.local/bin/devbox

# Run (in any project directory)
cd ~/my-project
devbox

# Inside container
opencode              # Start AI coding assistant
devbox-help           # Show all commands
```

First run builds the image (~5 min). Subsequent starts are instant.

## Standalone Mode (No Host Mounts)

For remote servers or fully isolated environments:

```bash
devbox --standalone myproject

# Inside container
devbox-setup                    # Configure git & GitHub
gh auth login                   # Authenticate
gh repo clone owner/repo        # Clone your code
opencode                        # Start coding
```

---

## Commands Reference

### Host Commands

```bash
devbox                      # Start shell in current directory
devbox opencode             # Start OpenCode directly
devbox exec <cmd>           # Run command in container
devbox --standalone [name]  # Isolated container with Docker volumes
devbox --standalone-list    # List standalone sessions
devbox --standalone-rm <n>  # Remove standalone session
devbox --tailscale          # Enable Tailscale VPN support
devbox --rebuild            # Rebuild Docker image
devbox --rebuild --no-cache # Full rebuild without cache
devbox --clean              # Remove project data
devbox --info               # Show container info
```

### Container Commands

```bash
devbox-help                 # Show all commands and configuration
devbox-setup                # Configure git, GitHub CLI, API keys
opencode                    # Start OpenCode AI assistant

# Tmux sessions (multiple projects)
tmux-dev                    # Session 'dev' in /workspace
tmux-dev backend ./backend  # Session 'backend' in ./backend
tmux-dev frontend ./frontend
tmux-list                   # List active sessions

# PostgreSQL
pg-start                    # Start PostgreSQL (auto-init on first run)
pg-stop                     # Stop PostgreSQL
pg-status                   # Show status and databases

# Tailscale VPN
tailscale-up                # Start and authenticate
tailscale-down              # Stop Tailscale
```

---

## Working with Multiple Projects

```bash
# Clone repos
cd /workspace
gh repo clone myorg/backend ./backend
gh repo clone myorg/frontend ./frontend

# Start separate tmux sessions
tmux-dev backend ./backend
# Ctrl+b d to detach

tmux-dev frontend ./frontend
# Ctrl+b d to detach

# Switch between sessions
tmux-list                   # See all sessions
tmux attach -t backend      # Attach to backend
```

---

## What's Included

| Category | Tools |
|----------|-------|
| **AI** | OpenCode |
| **Languages** | Python 3 (uv), Node.js LTS (nvm) |
| **Database** | PostgreSQL 15 |
| **Shell** | zsh, oh-my-zsh, starship prompt, fzf |
| **Dev Tools** | git, gh, vim, tmux, htop, direnv |
| **Search** | ripgrep (rg), fd, fzf |
| **Network** | Tailscale VPN, ping, telnet |

---

## Prerequisites

- **Docker** - [Install Docker](https://docs.docker.com/get-docker/)
- **Nerd Font** - Required for prompt icons ([nerdfonts.com](https://www.nerdfonts.com/))

---

## Pre-built Image

Skip local builds:

```bash
export DEVBOX_IMAGE=ghcr.io/spamsch/devbox:latest
# Add to ~/.bashrc or ~/.zshrc for persistence
```

---

## Authentication

### OpenCode

Works out of the box with free models. For more options:

```bash
# Inside opencode, run:
/connect

# Options:
# - Claude Pro/Max (browser auth)
# - API keys (Anthropic, OpenAI, etc.)
# - 75+ providers via Models.dev
```

### API Keys

Set before running devbox:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GH_TOKEN="ghp_..."
```

Or use a `.env` file in your project directory.

---

## Keyboard Shortcuts

### tmux

| Shortcut | Action |
|----------|--------|
| `Ctrl+b d` | Detach (session keeps running) |
| `Ctrl+b s` | List and switch sessions |
| `Ctrl+b c` | New window |
| `Ctrl+b n/p` | Next/previous window |
| `Ctrl+b %` | Split vertical |
| `Ctrl+b "` | Split horizontal |
| `Ctrl+b h/j/k/l` | Navigate panes |

### fzf

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Search command history |
| `Ctrl+T` | Find files |
| `Alt+C` | Change directory |

---

## Data Persistence

**Normal mode**: Data stored in `~/.devbox/projects/<hash>/`

**Standalone mode**: Docker volumes `devbox-<name>-workspace`, etc.

PostgreSQL data persists in both modes.

Clean up:
```bash
devbox --clean              # Current project
devbox --standalone-rm name # Standalone session
```

---

## Troubleshooting

```bash
# Docker permission denied
sudo usermod -aG docker $USER && newgrp docker

# Rebuild image
devbox --rebuild

# Full rebuild
devbox --rebuild --no-cache

# Reset project
devbox --clean

# Reset everything
rm -rf ~/.devbox && docker rmi devbox:latest
```

---

## Installing Docker (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
```

For Ubuntu, replace `debian` with `ubuntu`. See [Docker docs](https://docs.docker.com/engine/install/) for other distros.

---

## License

MIT
