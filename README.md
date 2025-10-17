# Claude YOLO Docker

A Docker wrapper for running Claude Code with `--dangerously-skip-permissions` in isolated environments.

## What This Does

This project creates a safe, isolated Docker container for running Claude Code in "YOLO mode" (skipping permission prompts). The container only has access to your current project directory, protecting the rest of your system.

## Features

- **Isolation**: Claude Code runs in a Docker container, not directly on your host
- **Directory Mounting**: Only your current directory is accessible to Claude
- **Persistent Authentication**: Auth tokens stored in a Docker volume, shared across all projects
- **User Mapping**: Files created by Claude maintain your user ownership
- **Interactive Mode**: Drop directly into Claude Code's CLI prompt
- **Debug Shell**: Access container shell after Claude exits for troubleshooting

## Prerequisites

- Docker installed and running
- Bash shell
- Claude account (you'll authenticate in-container on first run)

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

On first run, you'll be prompted to authenticate with your Claude account. After that, you'll be dropped directly into Claude Code's interactive prompt where you can type your commands.

When you exit Claude (type `/exit`), you'll drop into a bash shell inside the container for debugging. Type `exit` again to leave the container.

## How It Works

1. The wrapper script (`claude-yo`) captures your user ID, group ID, and current directory
2. It builds a Docker image (first run only) with Node.js and Claude Code installed
3. It starts a container that:
   - Mounts your current directory to `/workspace`
   - Mounts a persistent Docker volume for authentication data
   - Creates a user inside the container matching your host UID/GID
   - Restores authentication from previous sessions (if available)
   - Runs `claude --dangerously-skip-permissions` as that user
   - Saves authentication data back to the volume when you exit

## Important Security Notes

⚠️ **Always `cd` to your specific project directory before running!** 

Claude will have FULL ACCESS to the current directory and all subdirectories. Never run this in:
- Your home directory (`~`)
- System directories (`/`, `/etc`, `/usr`)
- Any directory containing sensitive data

The container provides isolation, but Claude still has unrestricted access to whatever directory you mount.

## Troubleshooting

**Image won't build**: Check that Docker is running and you have internet access for npm packages.

**Authentication not persisting**: The auth data is stored in a Docker volume named `claude-yolo-home`. Check it exists with `docker volume ls`. To reset authentication, remove the volume: `docker volume rm claude-yolo-home`

**Permission errors**: The script automatically matches your UID/GID, but if you still see issues, check Docker permissions.

**Terminal warnings**: You may see "cannot set terminal process group" warnings when dropping to the debug shell. These are harmless and don't affect functionality.

**Inspect persistent data**: View the volume contents with:
```bash
docker volume inspect claude-yolo-home
```

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
