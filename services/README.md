# Architecture

```mermaid
flowchart LR
    subgraph internet["Internet"]
        user["End User Device<br/>(Tailscale)"]
        lets_encrypt["Let's Encrypt"]

        subgraph aws["AWS"]
            r53["Route 53<br/>(DNS-01 TXT records)"]
        end
    end

    subgraph compute_node["Compute Node (Tailscale)"]
        subgraph caddy_svc["Caddy"]
            caddy["caddy<br/>:80 :443"]
        end

        subgraph vaultwarden_svc["Vaultwarden"]
            vaultwarden["vaultwarden<br/>:80<br/>:3012 (WebSocket)"]
        end

        subgraph immich_svc["Immich"]
            direction TB
            subgraph immich_internal["internal network"]
                immich["immich_server<br/>:2283"]
                ml["immich_machine_learning<br/>:3003"]
                redis["immich_redis<br/>:6379"]
                pg["immich_postgres<br/>:5432"]
            end
            immich --> ml
            immich --> redis
            immich --> pg
        end
    end

    user -->|"HTTPS via Tailscale"| caddy

    caddy -->|"vaultwarden subdomain"| vaultwarden
    caddy -->|"immich subdomain"| immich


    caddy -->|"DNS-01 challenge"| r53
    lets_encrypt -->|"validates TXT record"| r53
    caddy -->|"requests certificate"| lets_encrypt
```

## How It Works

### Routing

Caddy acts as the single entry point, listening on ports **80** and **443**. All traffic
from the internet hits Caddy first, which routes requests to the appropriate backend
service based on the subdomain.

### TLS Certificates (Route 53 DNS-01 Challenge)

Caddy automatically obtains and renews Let's Encrypt TLS certificates using the
**DNS-01 challenge** via the Route 53 plugin. Instead of requiring an open HTTP
port for validation, Caddy:

1. Creates a temporary `_acme-challenge` TXT record in the Route 53 hosted zone
2. Let's Encrypt validates the record
3. Caddy removes the TXT record and stores the certificate

This is configured via the `tls { dns route53 }` directive in the Caddyfile.
AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`)
are passed to the container through the `.env` file.

### DNS & Tailscale

The Route 53 hosted zone has an `A` record for `*.mydomain.com` pointing to
the compute node's **Tailscale IP** (e.g. `100.x.x.x`). Since Tailscale IPs are
private to the Tailscale network, only devices connected to the same Tailscale
network can reach these services — the public internet cannot resolve or route to
this address.

This means even though Caddy obtains publicly trusted Let's Encrypt certificates,
the services remain private and accessible only to authorized devices on the
Tailscale network.
