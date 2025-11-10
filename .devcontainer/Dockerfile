FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install basic dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    build-essential \
    curl \
    git \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    tmux \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install fish shell
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends software-properties-common \
    && apt-add-repository ppa:fish-shell/release-3 \
    && apt-get update \
    && apt-get -y install --no-install-recommends fish \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI with token available via secret
RUN --mount=type=secret,id=github_token \
    if [ -f /run/secrets/github_token ]; then \
      export GITHUB_TOKEN=$(cat /run/secrets/github_token); \
      echo "GitHub token available for gh installation"; \
    fi \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get -y install --no-install-recommends gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install mise with token available via secret
RUN --mount=type=secret,id=github_token \
    if [ -f /run/secrets/github_token ]; then \
      export GITHUB_TOKEN=$(cat /run/secrets/github_token); \
      echo "GitHub token available for mise installation"; \
    fi \
    && curl https://mise.run | sh 

# Install starship with token available via secret
RUN --mount=type=secret,id=github_token \
    if [ -f /run/secrets/github_token ]; then \
      export GITHUB_TOKEN=$(cat /run/secrets/github_token); \
      echo "GitHub token available for starship installation"; \
    fi \
    && curl -sS https://starship.rs/install.sh | sh -s -- --force

# Set role for dotfiles installation
ARG DOTPICKLES_ROLE=devcontainer
ENV DOTPICKLES_ROLE=${DOTPICKLES_ROLE}

# Switch to vscode user before installing dotfiles
USER vscode
WORKDIR /home/vscode

# Copy workspace to container (this will be the dotfiles repo)
# The build context is the repo root (../ from .devcontainer)
COPY --chown=vscode:vscode . /home/vscode/.pickles

# Run dotfiles installation with GitHub token available via secret
# The secret is mounted at /run/secrets/github_token and only available during this RUN command
RUN --mount=type=secret,id=github_token \
    cd /home/vscode/.pickles \
    && if [ -f /run/secrets/github_token ]; then \
         export GITHUB_TOKEN=$(cat /run/secrets/github_token); \
         echo "GitHub token available for dotfiles installation"; \
       else \
         echo "Warning: GitHub token not provided"; \
       fi \
    && bash install.sh

# Create workspace directory for cloned copy
USER root
RUN mkdir -p /workspace/dotfiles && chown -R vscode:vscode /workspace
USER vscode

# Set fish as default shell for vscode user
USER root
RUN chsh -s /usr/bin/fish vscode
USER vscode
