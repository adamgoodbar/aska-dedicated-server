#!/bin/bash

# Logging helper with timestamps
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Startup"

# reset log file
touch /tmp/app.stdout
cat /dev/null > /tmp/app.stdout

server_files="/home/container/server_files"
log "server path: $server_files"
savegame_files="/home/container/.wine/drive_c/users/container/AppData/LocalLow/Sand Sailor Studio/Aska/data/server"
log "savegame path: $savegame_files"

log "Installing Steam"

steam_path="/home/container/steamcmd"
mkdir -p "$steam_path"
curl -sSL -o "$steam_path/steamcmd.tar.gz" https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf "$steam_path/steamcmd.tar.gz" -C "$steam_path"
steamcmd="$steam_path/steamcmd.sh"
log "Steam ... OK"

log "Installing/Updating Aska Dedicated Server files ..."
validate_flag="validate"
if [ "$NO_VALIDATE" = "true" ]; then
  log "Skipping file integrity check (NO_VALIDATE=true)"
  validate_flag=""
fi

"$steamcmd" +@sSteamCmdForcePlatformType windows +force_install_dir "$server_files" +login anonymous +app_update 3246670 $validate_flag +quit
exit_code=$?

if [ $exit_code -ne 0 ]; then
  log "SteamCmd failed with exit code: $exit_code"
  log "Try deleting the appmanifest file or clear the whole server_files (installation only)"
  exit 1
else
  log "SteamCmd finished successfully (Exit Code: $exit_code)"
fi

log "Configuring Aska Dedicated Server ..."

# copy original to savegame
if [ ! -f "$savegame_files/my_server_properties.txt" ]; then
  cp "$server_files/server properties.txt" "$savegame_files/my_server_properties.txt" 2>&1
fi

# update env cfg data
source /home/container/scripts/env2cfg.sh

log "Launching Aska Dedicated Server"

# dedicated server guide says to use the .bat which is just this:
export SteamAppId=1898300

# Pattern that triggers a restart
RESTART_PATTERN="Uploading Crash Report"

# Verify server files directory exists
if [ ! -d "$server_files" ]; then
  log "ERROR: Server files directory not found: $server_files"
  exit 1
fi

cd "$server_files"

# Graceful shutdown handler
cleanup() {
  log "Received shutdown signal, stopping server..."
  if [ -n "$PIPE_PID" ]; then
    pkill -P "$PIPE_PID" 2>/dev/null
    kill "$PIPE_PID" 2>/dev/null
  fi
  exit 0
}
trap cleanup SIGTERM SIGINT

# RUN with output monitoring and auto-restart
while true; do
  log "Starting server..."

  # Reset log file for this run
  cat /dev/null > /tmp/app.stdout

  # Start server in background, piping output to tee
  xvfb-run --auto-servernum wine "$server_files/AskaServer.exe" -nographics -batchmode -propertiesPath 'C:/users/container/AppData/LocalLow/Sand Sailor Studio/Aska/data/server/my_server_properties.txt' 2>&1 | tee /tmp/app.stdout &
  PIPE_PID=$!

  # Monitor in main shell to avoid subshell issues with process control
  while kill -0 "$PIPE_PID" 2>/dev/null; do
    if grep -q "$RESTART_PATTERN" /tmp/app.stdout 2>/dev/null; then
      log "Detected crash pattern: $RESTART_PATTERN"
      log "Restarting server..."
      pkill -P "$PIPE_PID" 2>/dev/null
      kill "$PIPE_PID" 2>/dev/null
      break
    fi
    sleep 2
  done

  # Wait a moment before restarting
  log "Server stopped, restarting in 5 seconds..."
  sleep 5
done
