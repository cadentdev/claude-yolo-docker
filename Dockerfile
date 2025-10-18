FROM node:20-bookworm-slim

# Remove the node user to prevent UID collision with host users
RUN userdel -r node

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Set working directory where projects will be mounted
WORKDIR /workspace

# Default to bash (we'll override this in the wrapper script)
CMD ["/bin/bash"]

