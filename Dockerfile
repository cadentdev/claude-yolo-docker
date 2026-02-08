FROM python:3.12-slim-bookworm

# Install Node.js 20 and yq for YAML parsing
RUN apt-get update && \
    apt-get install -y curl yq && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code using native installer (recommended method)
# Native installer doesn't require Node.js but we keep it for user projects
ENV HOME=/root
RUN curl -fsSL https://claude.ai/install.sh | bash -s stable && \
    # Verify installation
    /root/.local/bin/claude --version

# Make Claude Code accessible to all users (native installer puts it in /root/.local/bin)
# chmod makes the path traversable; symlink provides a clean global path
RUN chmod 755 /root /root/.local /root/.local/bin && \
    ln -s /root/.local/bin/claude /usr/local/bin/claude

# Add Claude Code to PATH for root and disable auto-updates in container
ENV PATH="/root/.local/bin:${PATH}"
ENV DISABLE_AUTOUPDATER=1

# Set working directory where projects will be mounted
WORKDIR /workspace

# Default to bash (we'll override this in the wrapper script)
CMD ["/bin/bash"]

