# Setup
1. Make sure the `homelab` Docker network exists: `docker network create homelab`
1. Ensure the Caddy reverse proxy is running (see `services/caddy/`)

# Installation
1. Copy `.env.example` to `.env` and set your configuration
1. Generate a secure `STORYTELLER_SECRET_KEY`:
   ```
   openssl rand -base64 32
   ```
   Then paste the result into the `.env` file
1. Bring up the container: `docker compose up -d`

# Access
1. Storyteller is served through Caddy at the domain configured in `services/caddy/.env`
1. Open the domain in your browser to create your admin account