# Devbox

A batteries-included Docker development environment for AI-assisted coding with [OpenCode](https://opencode.ai/) and [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Spin up a fully configured workspace in seconds — no setup required.

### Sensible Defaults, Pre-configured

- **Shell** — Zsh with Oh-My-Zsh, autosuggestions, syntax highlighting, and a [Starship](https://starship.rs/) prompt. 50k-line shared history with deduplication, auto-cd, typo correction, and extended globbing.
- **Editor** — Vim with relative line numbers, smart-case search, persistent undo, space as leader key, and 26+ selectable themes (`vim-theme`). 2-space indent for JS/TS/JSON/YAML, 4-space for everything else.
- **Tmux** — Mouse support, vim-style pane navigation, 50k-line scrollback, true color, and a ready-made 3-pane dev layout (`Ctrl+b D`).
- **Git** — Host `.gitconfig` and SSH keys imported automatically. Defaults to `main` branch, `pull.rebase=false`, and `core.autocrlf=input`.
- **Python** — Managed by [uv](https://docs.astral.sh/uv/). Auto-creates `.venv` when `requirements.txt` or `pyproject.toml` is detected.
- **Node.js** — LTS version via [nvm](https://github.com/nvm-sh/nvm), ready to use.
- **PostgreSQL 15** — One-command start (`pg-start`), auto-initializes on first run with a `dev` database and [pgvector](https://github.com/pgvector/pgvector) extension pre-installed. Trust auth for local connections.
- **Search** — ripgrep, fd, and fzf wired together. `Ctrl+R` for history, `Ctrl+T` for files, `Alt+C` for directories — all with preview windows.
- **Direnv** — Host approvals carried over so `.envrc` files work without re-allowing inside the container.
- **Locale** — UTF-8 (`en_US.UTF-8`) everywhere.

## Quick Start

### Option A: On a Server (just Docker needed)

```bash
docker run -it --name devbox ghcr.io/spamsch/devbox:latest

# Inside container
devbox-setup                    # Configure git & GitHub
gh auth login                   # Authenticate
gh repo clone owner/repo        # Clone your code
opencode                        # Start OpenCode AI assistant
claude                          # Or start Claude Code
```

Container persists after exit. Reattach with `docker start -ai devbox`.

**With Tailscale VPN:**

```bash
docker run -it --name devbox \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --device=/dev/net/tun \
  -v devbox-tailscale:/var/lib/tailscale \
  ghcr.io/spamsch/devbox:latest

# Inside container
tailscale-up                    # Start Tailscale and authenticate
```

### Option B: Local Development (mount your project)

```bash
# Install
git clone https://github.com/spamsch/devbox.git ~/.devbox-source
ln -s ~/.devbox-source/devbox ~/.local/bin/devbox

# Run (in any project directory)
cd ~/my-project
devbox

# Inside container
opencode              # Start OpenCode AI assistant
claude                # Or start Claude Code
devbox-help           # Show all commands
```

First run builds the image (~5 min). Subsequent starts are instant.

### Option C: Standalone Mode (isolated with volumes)

```bash
devbox --standalone myproject

# Inside container
devbox-setup                    # Configure git & GitHub
gh auth login                   # Authenticate
gh repo clone owner/repo        # Clone your code
opencode                        # Start OpenCode AI assistant
claude                          # Or start Claude Code
```

Uses Docker volumes for persistence. List sessions with `devbox --standalone-list`.

---

## Commands Reference

### Host Commands

```bash
devbox                      # Start shell in current directory
devbox opencode             # Start OpenCode directly
devbox claude               # Start Claude Code directly
devbox exec <cmd>           # Run command in container
devbox --standalone [name]  # Isolated container with Docker volumes
devbox --standalone-list    # List standalone sessions
devbox --standalone-rm <n>  # Remove standalone session
devbox --tailscale          # Enable Tailscale VPN support
devbox --rebuild            # Rebuild Docker image
devbox --rebuild --no-cache # Full rebuild without cache
devbox --clean              # Remove project data
devbox --info               # Show container info
devbox --vscode             # Enable VS Code server (port 18080)
```

### Container Commands

```bash
devbox-help                 # Show all commands and configuration
devbox-setup                # Configure git, GitHub CLI, API keys
opencode                    # Start OpenCode AI assistant
claude                      # Start Claude Code

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

# VS Code (browser-based)
vscode-start                # Start code-server on port 18080
vscode-stop                 # Stop code-server
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
| **AI Agents** | OpenCode, Claude Code |
| **Languages** | Python 3 (uv), Node.js LTS (nvm) |
| **Database** | PostgreSQL 15 |
| **Shell** | zsh, oh-my-zsh, starship prompt, fzf |
| **Dev Tools** | git, gh, vim, tmux, htop, direnv |
| **Editor** | code-server (VS Code in browser) |
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
# CLI authentication (no TUI needed)
opencode auth login
# Select provider, authenticate via browser

# Or inside the TUI:
/connect
```

Options:
- Claude Pro/Max (browser auth)
- API keys (Anthropic, OpenAI, etc.)
- 75+ providers via Models.dev

```bash
# Manage auth
opencode auth list              # List connected providers
opencode auth logout            # Remove credentials
```

### Claude Code

Claude Code authenticates via browser on first run:

```bash
claude                          # Opens browser for authentication
```

Or use an API key:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
claude
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
| `Ctrl+b z` | Zoom/unzoom pane (fullscreen toggle) |
| `Ctrl+b c` | New window |
| `Ctrl+b n/p` | Next/previous window |
| `Ctrl+b %` | Split vertical |
| `Ctrl+b "` | Split horizontal |
| `Ctrl+b h/j/k/l` | Navigate panes |

### Container

| Shortcut | Action |
|----------|--------|
| `Ctrl+p Ctrl+q` | Detach (container keeps running) |
| `exit` / `Ctrl+d` | Exit and stop container |

Reattach with: `docker attach <container-name>`

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
