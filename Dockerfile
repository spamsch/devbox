# =============================================================================
# Devbox - Development Container for OpenCode with Python & JavaScript
# =============================================================================
#
# A Docker-based development environment optimized for AI-assisted coding.
# Includes: OpenCode, Python (uv), Node.js (nvm), tmux, zsh, starship
#
# Build:  docker build -t devbox:latest .
# Run:    See the 'devbox' launcher script
#
# =============================================================================

FROM debian:bookworm

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
# Prevent interactive prompts during apt installations
ENV DEBIAN_FRONTEND=noninteractive
# Set locale to UTF-8 for proper character handling
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# -----------------------------------------------------------------------------
# System Dependencies
# -----------------------------------------------------------------------------
# Install all system packages in a single layer for efficiency.
# Using --no-install-recommends to keep the image size small.
#
# Package categories:
#   - Essential: ca-certificates, curl, wget, gnupg, sudo
#   - Build tools: build-essential, pkg-config (for native npm/pip packages)
#   - Shell: zsh, locales
#   - Development: git, vim, tmux, htop
#   - Search tools: ripgrep, fd-find, fzf
#   - Utilities: jq, direnv, tree, unzip
#   - Network: openssh-client (for git over SSH)
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essential tools
    ca-certificates \
    curl \
    wget \
    gnupg \
    sudo \
    # Build tools (needed for native npm/pip packages)
    build-essential \
    pkg-config \
    libssl-dev \
    libffi-dev \
    # Shell and locale
    zsh \
    locales \
    # Development tools
    git \
    vim \
    tmux \
    htop \
    tree \
    # Search tools
    ripgrep \
    fzf \
    # Note: fd is packaged as 'fd-find' in Debian
    fd-find \
    # Utilities
    jq \
    direnv \
    unzip \
    # Network tools (for git SSH)
    openssh-client \
    # Python build dependencies (for packages with native extensions)
    python3-dev \
    && \
    # -----------------------------------------------------------------------------
    # Locale Configuration
    # -----------------------------------------------------------------------------
    # Generate UTF-8 locale for proper character handling
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    # -----------------------------------------------------------------------------
    # Create symlink for fd (Debian names it 'fdfind')
    # -----------------------------------------------------------------------------
    ln -s /usr/bin/fdfind /usr/local/bin/fd && \
    # -----------------------------------------------------------------------------
    # Cleanup
    # -----------------------------------------------------------------------------
    # Remove apt cache to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# GitHub CLI Installation
# -----------------------------------------------------------------------------
# Install gh (GitHub CLI) from the official GitHub repository.
# This provides better GitHub integration than using git alone.
# -----------------------------------------------------------------------------
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod 644 /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y gh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Starship Prompt Installation
# -----------------------------------------------------------------------------
# Starship is a fast, customizable prompt that works with any shell.
# We install it system-wide so it's available for all users.
# -----------------------------------------------------------------------------
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# -----------------------------------------------------------------------------
# User Creation
# -----------------------------------------------------------------------------
# Create a non-root user 'dev' for running the container.
# The UID/GID can be overridden at build time to match the host user,
# which prevents permission issues with mounted volumes.
#
# Arguments:
#   USER_ID  - User ID (default: 1000)
#   GROUP_ID - Group ID (default: 1000)
#   USERNAME - Username (default: dev)
# -----------------------------------------------------------------------------
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=dev

RUN groupadd -g ${GROUP_ID} ${USERNAME} 2>/dev/null || true && \
    useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/zsh ${USERNAME} && \
    # Grant sudo access without password (useful for installing packages)
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# -----------------------------------------------------------------------------
# Switch to Non-Root User
# -----------------------------------------------------------------------------
# All following commands run as the 'dev' user for security.
# -----------------------------------------------------------------------------
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# -----------------------------------------------------------------------------
# uv Installation (Python Package Manager)
# -----------------------------------------------------------------------------
# uv is a fast Python package manager written in Rust.
# It's significantly faster than pip and handles virtual environments well.
# See: https://github.com/astral-sh/uv
# -----------------------------------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# -----------------------------------------------------------------------------
# Node.js Installation via NVM
# -----------------------------------------------------------------------------
# NVM (Node Version Manager) allows easy switching between Node.js versions.
# We install the LTS version as the default.
# -----------------------------------------------------------------------------
ENV NVM_DIR="/home/${USERNAME}/.nvm"

# Install NVM and Node.js LTS
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    # Source NVM and install Node.js LTS
    . "$NVM_DIR/nvm.sh" && \
    nvm install --lts && \
    nvm alias default node && \
    nvm use default

# -----------------------------------------------------------------------------
# Oh-My-Zsh Installation
# -----------------------------------------------------------------------------
# Oh-My-Zsh provides a framework for managing zsh configuration.
# We'll use it for plugins but disable the theme (using Starship instead).
# -----------------------------------------------------------------------------
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# -----------------------------------------------------------------------------
# Zsh Plugins Installation
# -----------------------------------------------------------------------------
# Install additional zsh plugins for a better shell experience:
#   - zsh-autosuggestions: Fish-like command suggestions
#   - zsh-syntax-highlighting: Syntax highlighting for commands
# -----------------------------------------------------------------------------
RUN git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# -----------------------------------------------------------------------------
# OpenCode Installation
# -----------------------------------------------------------------------------
# OpenCode is the open source AI coding agent from https://opencode.ai/
# Install via the official installer script.
# This is done last to allow easy updates by rebuilding just this layer.
#
# OpenCode installs to ~/.opencode/bin/opencode
# The installer modifies .zshrc to add it to PATH, but we also add it
# explicitly to ensure it's available in all contexts.
#
# The BUILD_TIMESTAMP argument can be changed to force a rebuild of this layer,
# which will install the latest version of OpenCode.
# -----------------------------------------------------------------------------
ARG BUILD_TIMESTAMP=unknown
RUN curl -fsSL https://opencode.ai/install | bash && \
    # Verify installation
    $HOME/.opencode/bin/opencode --version

# Add opencode to PATH explicitly (installer adds to .zshrc but we want it everywhere)
ENV PATH="/home/${USERNAME}/.opencode/bin:${PATH}"

# -----------------------------------------------------------------------------
# Directory Setup
# -----------------------------------------------------------------------------
# Create directories that will be used for configuration and data.
# These may be overwritten by volume mounts at runtime.
# -----------------------------------------------------------------------------
RUN mkdir -p /home/${USERNAME}/.config \
             /home/${USERNAME}/.local/share \
             /home/${USERNAME}/.cache \
             /home/${USERNAME}/.tmux \
             /home/${USERNAME}/workspace

# -----------------------------------------------------------------------------
# Copy Configuration Files
# -----------------------------------------------------------------------------
# Copy default configuration files into the image.
# These provide sensible defaults that can be customized via volume mounts.
# -----------------------------------------------------------------------------
COPY --chown=${USERNAME}:${USERNAME} config/starship.toml /home/${USERNAME}/.config/starship.toml
COPY --chown=${USERNAME}:${USERNAME} config/tmux.conf /home/${USERNAME}/.tmux.conf
COPY --chown=${USERNAME}:${USERNAME} config/tmux/dev-layout.conf /home/${USERNAME}/.tmux/dev-layout.conf
COPY --chown=${USERNAME}:${USERNAME} config/vimrc /home/${USERNAME}/.vimrc
COPY --chown=${USERNAME}:${USERNAME} config/zshrc /home/${USERNAME}/.zshrc

# -----------------------------------------------------------------------------
# Copy Scripts
# -----------------------------------------------------------------------------
# Copy the setup wizard and utility scripts.
# -----------------------------------------------------------------------------
COPY --chown=${USERNAME}:${USERNAME} scripts/setup.sh /home/${USERNAME}/.local/bin/devbox-setup
COPY --chown=${USERNAME}:${USERNAME} scripts/tmux-dev /home/${USERNAME}/.local/bin/tmux-dev
RUN chmod +x /home/${USERNAME}/.local/bin/devbox-setup \
             /home/${USERNAME}/.local/bin/tmux-dev

# Switch to root to copy entrypoint to system location
USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch back to dev user
USER ${USERNAME}

# -----------------------------------------------------------------------------
# Working Directory
# -----------------------------------------------------------------------------
# Set the default working directory to /workspace where projects are mounted.
# -----------------------------------------------------------------------------
WORKDIR /workspace

# -----------------------------------------------------------------------------
# Entrypoint and Default Command
# -----------------------------------------------------------------------------
# The entrypoint script handles initialization tasks.
# The default command starts an interactive zsh shell.
# -----------------------------------------------------------------------------
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/zsh"]
