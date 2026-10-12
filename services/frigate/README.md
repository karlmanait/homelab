# Setup
1. Make sure the `homelab` Docker network exists: `docker network create homelab`
1. Ensure the Caddy reverse proxy is running (see `services/caddy/`)
1. Ensure the ip-cam is streaming via MediaMTX (see `metal/ip-cam/`)

# Installation
1. Copy `.env.example` to `.env` and set your configuration
1. Set `FRIGATE_RTSP_PASSWORD` to the password of the `frigate` user in the ip-cam's `mediamtx.yml`
1. Review the camera address and recording retention in `config/config.yml`
1. Bring up the container: `docker compose up -d`

# Access
1. Frigate is served through Caddy at the domain configured in `services/caddy/.env`
1. On first start, Frigate creates an `admin` user with a random password:
   ```
   docker logs frigate 2>&1 | grep -i password
   ```
