FROM node:20-bookworm-slim

# Install Claude Code globally
RUN npm install -g @anthropics/claude-code

# Set working directory where projects will be mounted
WORKDIR /workspace

# Default to bash (we'll override this in the wrapper script)
CMD ["/bin/bash"]

