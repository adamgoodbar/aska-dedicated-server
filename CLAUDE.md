# CLAUDE.md - Project Guide for Claude Code

## Project Overview

This is a Docker-based dedicated server solution for **Aska**, a multiplayer survival game by Sand Sailor Studio. It provides a containerized environment that downloads, installs, configures, and manages an Aska dedicated server with automatic crash detection and recovery.

## Tech Stack

- **Container**: Docker with Wine (for Windows executable compatibility)
- **Base Image**: `ghcr.io/ptero-eggs/yolks:wine_latest`
- **Scripts**: Bash
- **CI/CD**: GitHub Actions → GitHub Container Registry (GHCR)
- **Game Server**: SteamCMD downloads App ID 3246670

## Project Structure

```
├── Dockerfile              # Container build configuration
├── files/
│   ├── entrypoint.sh       # Container entry point wrapper
│   ├── start.sh            # Main startup, download, and crash recovery logic
│   └── env2cfg.sh          # Maps environment variables to server config
├── .github/workflows/
│   └── docker-image.yml    # CI/CD pipeline for image builds
```

## Key Files

- **start.sh** - Core logic: Steam/SteamCMD installation, server file download, configuration setup, server execution with crash monitoring loop
- **env2cfg.sh** - Translates environment variables (SERVER_NAME, REGION, etc.) to server properties file
- **Dockerfile** - Defines health check that detects crashes and triggers container restart

## Build & Run

```bash
# Build image locally
docker build -t aska-server .

# Run with docker-compose (see README.md for full example)
docker compose up -d
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `AUTHENTICATION_TOKEN` | Required Steam auth token |
| `SESSION_NAME` | Server list display name |
| `SERVER_NAME` | Host name in browser |
| `REGION` | Server region (default = auto) |
| `PASSWORD` | Server password |
| `SERVER_PORT` | Gameplay UDP port (default: 27015) |
| `SERVER_QUERY_PORT` | Browser query port (default: 27016) |
| `KEEP_WORLD_ALIVE` | Update world without players |
| `AUTOSAVE_STYLE` | Save frequency setting |
| `SAVE_ID` | Override savegame ID |
| `NO_VALIDATE` | Skip Steam file validation |

## Architecture Notes

- Server runs via Wine + xvfb (virtual framebuffer for headless operation)
- Crash detection monitors `/tmp/app.stdout` for "Uploading Crash Report" pattern
- Health check triggers container restart on crash detection
- start.sh also has internal crash loop that restarts before container does

## Common Tasks

### Modifying server configuration options
Edit `files/env2cfg.sh` to add new environment variable mappings

### Changing startup behavior
Edit `files/start.sh` - main server execution is at the bottom in the while loop

### Adjusting crash detection
- Health check timing: modify `HEALTHCHECK` in Dockerfile
- Crash patterns: modify grep patterns in both Dockerfile and start.sh

## Volumes

- **savegame**: `/home/container/.wine/drive_c/users/container/AppData/LocalLow/Sand Sailor Studio/Aska/data/server`
- **server**: `/home/container/server_files` (cached server binaries)

## Testing Changes

1. Build locally: `docker build -t aska-test .`
2. Run with test config and check logs
3. CI/CD automatically builds on push to main or version tags
