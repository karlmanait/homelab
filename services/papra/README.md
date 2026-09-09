# Setup
1. Make sure the `homelab` Docker network exists: `docker network create homelab`
1. Ensure the Caddy reverse proxy is running (see `services/caddy/`)

# Installation
1. Copy `.env.example` to `.env` and set your configuration:
1. Edit the values in `.env` (app secret key, app URL, etc.)
1. Bring up the container: `docker compose up -d`

# Access
1. Papra is served through Caddy at the domain configured in `services/caddy/.env`
