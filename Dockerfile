FROM python:3.12-slim-bookworm

# Install Node.js 20, yq for YAML parsing, and Claude Code
RUN apt-get update && \
    apt-get install -y curl yq && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g @anthropic-ai/claude-code

# Set working directory where projects will be mounted
WORKDIR /workspace

# Default to bash (we'll override this in the wrapper script)
CMD ["/bin/bash"]

