FROM ghcr.io/ptero-eggs/yolks:wine_latest

LABEL author="struppi" maintainer="https://github.com/struppinet"
LABEL org.opencontainers.image.description="Docker container for Aska dedicated server with auto-restart on crash"
LABEL org.opencontainers.image.source="https://github.com/adamgoodbar/aska-dedicated-server"
LABEL org.opencontainers.image.licenses="GPL-3.0"

# healthcheck
HEALTHCHECK --interval=5s --start-period=60s --start-interval=15s CMD ! grep -Eq "Uploading Crash Report|A crash has been intercepted by the crash handler" /tmp/app.stdout || exit 1

# Document exposed ports
EXPOSE 27015/udp
EXPOSE 27016/udp

# Server files volume
VOLUME ["/home/container/server_files"]

# Savegame volume (fixed Wine path required by Aska)
RUN mkdir -p "/home/container/.wine/drive_c/users/container/AppData/LocalLow/Sand Sailor Studio/Aska/data/server"
VOLUME ["/home/container/.wine/drive_c/users/container/AppData/LocalLow/Sand Sailor Studio/Aska/data/server"]

ADD ./files /home/container/scripts
RUN chmod +x /home/container/scripts/*.sh

ENTRYPOINT ["/bin/bash", "/home/container/scripts/entrypoint.sh"]
CMD ["/home/container/scripts/start.sh"]
