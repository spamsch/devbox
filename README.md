# Devbox

A Docker-based development environment for AI-assisted coding with [OpenCode](https://opencode.ai/), Python, and JavaScript.

## Features

- **OpenCode** - Open source AI coding agent pre-installed
- **Python** - Managed via `uv` (fast Python package manager)
- **Node.js** - Managed via `nvm` (Node Version Manager)
- **Modern Shell** - zsh with oh-my-zsh, starship prompt, and fzf
- **tmux** - Terminal multiplexer for session management
- **Per-Project Isolation** - Each project gets its own container data
- **Sensible Defaults** - Works out of the box, customize as needed

## Prerequisites

- **Docker** - Must be installed and running
- **Nerd Font** - Required for the starship prompt icons
  - Install from [nerdfonts.com](https://www.nerdfonts.com/)
  - Recommended: JetBrainsMono Nerd Font, FiraCode Nerd Font, or Hack Nerd Font
  - Configure your terminal to use the Nerd Font

## Quick Start

### 1. Install

Clone this repository and add `devbox` to your PATH:

```bash
git clone https://github.com/yourusername/devbox.git ~/.devbox-source
ln -s ~/.devbox-source/devbox ~/.local/bin/devbox
```

#### Using Pre-built Image

Alternatively, you can use the pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/yourusername/devbox:latest
```

Then run directly:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.ssh:/home/dev/.ssh:ro \
  ghcr.io/yourusername/devbox:latest
```

### 2. Run

Navigate to any project directory and run:

```bash
cd ~/my-project
devbox
```

The first run will:
1. Build the Docker image (takes a few minutes)
2. Start an interactive shell in the container
3. Show the setup wizard for first-time configuration

### 3. Start Coding

```bash
# Start OpenCode AI assistant
opencode

# Or run it directly from outside the container
devbox opencode
```

## Usage

```bash
devbox                      # Start interactive shell (default)
devbox shell                # Same as above
devbox opencode             # Start OpenCode AI assistant
devbox exec <cmd>           # Run a command in the container
devbox --rebuild            # Force rebuild the Docker image
devbox --clean              # Remove container and data for current project
devbox --info               # Show container and project information
devbox --help               # Show help message
```

### Examples

```bash
# Start working on a project
cd ~/projects/my-app
devbox

# Run Python scripts
devbox exec python app.py

# Run npm commands
devbox exec npm install
devbox exec npm test

# Run multiple commands
devbox exec bash -c "npm install && npm test"
```

## First-Time Setup

When you first enter a container, you'll see:

```
Devbox - Development Environment
────────────────────────────────────────────────────
  Project:    /workspace
  Python:     3.11.x (uv available)
  Node.js:    v20.x.x
  OpenCode:   x.x.x
────────────────────────────────────────────────────

  First time setup!
  Run devbox-setup to configure git and GitHub CLI.
  Run opencode to start coding.
```

Run `devbox-setup` to configure:

1. **Git identity** - Your name and email for commits
2. **GitHub CLI** - Authentication for repository operations

OpenCode works out of the box with free models, or you can:
- Use your **Claude Pro/Max** account via browser login
- Set `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` for API access
- Connect 75+ providers through [Models.dev](https://models.dev)

You can re-run `devbox-setup` anytime to update your configuration.

## Authentication

### OpenCode

OpenCode includes free models out of the box. Just run:

```bash
opencode
```

For additional models, you have several options:

#### Option 1: Claude Pro/Max (Recommended)

If you have a Claude Pro or Max subscription:

```bash
# Inside opencode, run:
/connect

# Select: Anthropic → Claude Pro/Max
# Authenticate via browser when prompted
```

#### Option 2: API Keys

Set environment variables before running devbox:

```bash
# Set in your shell profile (~/.bashrc, ~/.zshrc)
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."

# Or use a project .env file
echo "ANTHROPIC_API_KEY=sk-ant-..." >> .env
```

Environment variables are automatically passed to the container.

#### Option 3: Other Providers

OpenCode supports 75+ providers including OpenAI, Google, xAI, DeepSeek, and local models via Ollama.

```bash
# Inside opencode, run:
/connect

# Select your provider and follow the prompts
```

See [OpenCode providers docs](https://opencode.ai/docs/providers) for the full list.

## Included Tools

### Languages & Package Managers

| Tool | Description |
|------|-------------|
| Python 3 | Latest stable version |
| uv | Fast Python package manager |
| Node.js | LTS version via nvm |
| npm | Node package manager |

### Development Tools

| Tool | Description |
|------|-------------|
| git | Version control |
| gh | GitHub CLI |
| vim | Text editor (with sensible config) |
| tmux | Terminal multiplexer |
| htop | Process viewer |

### Search Tools

| Tool | Description |
|------|-------------|
| ripgrep (`rg`) | Fast text search |
| fd | Fast file finder |
| fzf | Fuzzy finder |

### Shell

| Tool | Description |
|------|-------------|
| zsh | Shell with oh-my-zsh |
| starship | Cross-shell prompt (gruvbox-rainbow theme) |
| direnv | Directory-specific env vars |

**Note:** The starship prompt uses the Gruvbox Rainbow preset which requires a [Nerd Font](https://www.nerdfonts.com/) installed in your terminal. Recommended: JetBrainsMono Nerd Font, FiraCode Nerd Font, or Hack Nerd Font.

## Keyboard Shortcuts

### fzf (Fuzzy Finder)

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Search command history |
| `Ctrl+T` | Find files in current directory |
| `Alt+C` | Change to a subdirectory |
| `**<Tab>` | Fuzzy completion (e.g., `vim **<Tab>`) |

### tmux

**Quick Start with Dev Layout:**

```bash
tmux-dev              # Start tmux with 3-pane dev layout
tmux-dev myproject    # Start with custom session name
```

This creates a layout optimized for development:

```
┌────────────────────┬────────────────────┐
│                    │      terminal      │
│     main pane      ├────────────────────┤
│   (opencode/vim)   │      terminal      │
└────────────────────┴────────────────────┘
```

**Session Management:**

```bash
tmux-dev              # Start or attach to 'dev' session
tmux attach -t dev    # Attach to existing 'dev' session
tmux ls               # List all sessions
Ctrl+b d              # Detach from session (keeps it running)
```

**Shortcuts:**

| Shortcut | Action |
|----------|--------|
| `Ctrl+b d` | Detach from session (session keeps running) |
| `Ctrl+b D` | Apply dev layout to current session |
| `Ctrl+b \|` | Split pane horizontally |
| `Ctrl+b -` | Split pane vertically |
| `Ctrl+b h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl+b c` | Create new window |
| `Ctrl+b n/p` | Next/previous window |
| `Ctrl+b r` | Reload tmux config |

### vim

| Shortcut | Action |
|----------|--------|
| `Space w` | Save file |
| `Space q` | Quit |
| `Ctrl+h/j/k/l` | Navigate splits |
| `/pattern` | Search forward |
| `n/N` | Next/previous match |

## Data Persistence

Each project stores its data in `~/.devbox/projects/<hash>/`:

```
~/.devbox/
├── projects/
│   ├── a1b2c3d4/           # Project 1
│   │   ├── config/         # Tool configurations
│   │   ├── cache/          # Package caches
│   │   └── data/           # Persistent app data
│   └── e5f6g7h8/           # Project 2
│       └── ...
└── .last-build             # Image build timestamp
```

Data persists between container runs. Use `devbox --clean` to remove it.

## Customization

### Configuration Files

The container includes sensible defaults for all tools. To customize:

1. **Starship prompt**: `~/.config/starship.toml`
2. **tmux**: `~/.tmux.conf`
3. **vim**: `~/.vimrc`
4. **zsh**: `~/.zshrc`

These files are in the container. To make changes permanent, modify the files in the `config/` directory and rebuild:

```bash
# Edit config/starship.toml, config/tmux.conf, etc.
devbox --rebuild
```

### Adding Tools

To add more tools to the container, edit the `Dockerfile` and rebuild:

```bash
vim Dockerfile
# Add your packages to the apt-get install section
devbox --rebuild
```

## Troubleshooting

### Docker Permission Denied

If you get permission errors, make sure your user is in the docker group:

```bash
sudo usermod -aG docker $USER
# Log out and back in, or run:
newgrp docker
```

### Container Won't Start

Check Docker is running:

```bash
docker info
```

Force rebuild the image:

```bash
devbox --rebuild
```

### File Permission Issues

The container runs with your user's UID/GID. If you see permission errors, rebuild the image:

```bash
devbox --rebuild
```

### Reset Project Data

To start fresh for a project:

```bash
devbox --clean
```

### Reset Everything

To remove all devbox data:

```bash
rm -rf ~/.devbox
docker rmi devbox:latest
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Container (devbox)                 │
├─────────────────────────────────────────────────────────────┤
│  Base: Debian Bookworm (stable)                             │
├─────────────────────────────────────────────────────────────┤
│  Shell: zsh + oh-my-zsh + starship + fzf                    │
├─────────────────────────────────────────────────────────────┤
│  Languages: Python (uv) + Node.js (nvm)                     │
├─────────────────────────────────────────────────────────────┤
│  AI: OpenCode                                               │
├─────────────────────────────────────────────────────────────┤
│  Tools: git, gh, vim, tmux, ripgrep, fd, htop               │
└─────────────────────────────────────────────────────────────┘

Volume Mounts:
  ~/project     → /workspace        (your code)
  ~/.ssh        → /home/dev/.ssh    (SSH keys, read-only)
  ~/.gitconfig  → /tmp/host_gitconfig (git config import)
  ~/.devbox/... → /home/dev/...     (persistent data)
```

## License

MIT License - See [LICENSE](LICENSE) for details.
