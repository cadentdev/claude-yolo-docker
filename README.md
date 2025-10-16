# Claude YOLO Docker

A Docker wrapper for running Claude Code with `--dangerously-skip-permissions` in isolated environments.

## What This Does

This project creates a safe, isolated Docker container for running Claude Code in "YOLO mode" (skipping permission prompts). The container only has access to your current project directory, protecting the rest of your system.

## Features

- **Isolation**: Claude Code runs in a Docker container, not directly on your host
- **Directory Mounting**: Only your current directory is accessible to Claude
- **Authentication Passthrough**: Your `~/.claude` credentials are mounted (read-only)
- **User Mapping**: Files created by Claude maintain your user ownership
- **Interactive Mode**: Drop directly into Claude Code's CLI prompt

## Prerequisites

- Docker installed and running
- Claude Code authentication set up (`claude login` on your host machine)
- Bash shell

## Installation

1. Clone this repository:
```bash
git clone https://github.com/cadentdev/claude-yolo-docker.git
cd claude-yolo-docker
```

2. Make the wrapper script executable:
```bash
chmod +x claude-yo
```

3. (Optional) Add to your PATH or create a symlink:
```bash
# Option A: Symlink to a directory in your PATH
ln -s "$(pwd)/claude-yo" ~/.local/bin/claude-yolo

# Option B: Add this directory to your PATH
echo 'export PATH="$PATH:'$(pwd)'"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

Navigate to your project directory and run:
```bash
cd ~/my-project
/path/to/claude-yolo-docker/claude-yo
```

Or if you added it to your PATH:
```bash
cd ~/my-project
claude-yo
```

You'll be dropped directly into Claude Code's interactive prompt where you can type your commands.

## How It Works

1. The wrapper script (`claude-yo`) captures your user ID, group ID, and current directory
2. It builds a Docker image (first run only) with Node.js and Claude Code installed
3. It starts a container that:
   - Mounts your current directory to `/workspace`
   - Mounts your `~/.claude` credentials (read-only)
   - Creates a user inside the container matching your host UID/GID
   - Runs `claude --dangerously-skip-permissions` as that user

## Important Security Notes

⚠️ **Always `cd` to your specific project directory before running!** 

Claude will have FULL ACCESS to the current directory and all subdirectories. Never run this in:
- Your home directory (`~`)
- System directories (`/`, `/etc`, `/usr`)
- Any directory containing sensitive data

The container provides isolation, but Claude still has unrestricted access to whatever directory you mount.

## Troubleshooting

**Image won't build**: Check that Docker is running and you have internet access for npm packages.

**Authentication fails**: Make sure you've run `claude login` on your host machine and `~/.claude` exists.

**Permission errors**: The script automatically matches your UID/GID, but if you still see issues, check Docker permissions.

## Learning Resources

This project was built as a learning exercise to understand:
- Docker basics (Dockerfiles, images, containers)
- Volume mounting and bind mounts
- User ID mapping between host and container
- Writing wrapper scripts for Docker workflows

## License

MIT

## Contributing

Issues and pull requests welcome!
