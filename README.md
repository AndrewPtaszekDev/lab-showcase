# Homelab

Self-hosted infrastructure running on Proxmox, orchestrated with Docker Compose and fronted by Traefik.

> **Note:** This is a sanitized copy of a live configuration. All secrets, credentials, and private domains have been replaced with descriptive placeholders. It is not intended to be deployed as-is.

## Architecture

```
Internet
  │
  ▼
Cloudflare DNS (wildcard *.example.com)
  │
  ▼
Traefik v3 ─── automatic Let's Encrypt TLS (DNS-01 via Cloudflare)
  │
  ├── example.com          → Quartz (static docs site)
  ├── blog.example.com     → Ghost (blog)
  ├── docs.example.com     → Quartz (internal docs, basic-auth)
  ├── grafana.example.com  → Grafana (VPN-only IP allowlist)
  ├── remark.example.com   → Remark42 (comments)
  └── umami.example.com    → Umami (analytics)
```

## Services

### Reverse Proxy & TLS
- **Traefik v3** — edge router with automatic wildcard certificates, per-route middleware (basic auth, IP allowlisting), and JSON access logging

### Publishing
- **Ghost** — blog platform backed by MySQL
- **Quartz** — two instances rendering Obsidian vaults as static sites, pulled from Gitea repos
- **Remark42** — self-hosted comment engine with GitHub & Google OAuth
- **Umami** — privacy-focused web analytics

### Version Control & CI
- **Gitea** — self-hosted Git forge backed by PostgreSQL
- **Gitea Act Runner** — CI runner executing workflows in Docker containers

### Observability
- **Prometheus** — metrics collection from cAdvisor and Node Exporter agents across VMs
- **Grafana** — dashboards for container metrics, node health, and log exploration
- **Loki + Promtail** — log aggregation from Docker containers and systemd journals
- **cAdvisor** — container resource usage metrics
- **Traefik Log Dashboard** — ingress analytics with GeoIP enrichment

### Other
- **Calibre Web Automated** — ebook library with automated ingestion
- **PostgreSQL 14** — shared database for Gitea and Umami

## Networking

| Network          | Purpose                                              |
|------------------|------------------------------------------------------|
| `proxy`          | Traefik ↔ public-facing services                     |
| `monitoring`     | Internal-only bridge for the observability stack      |
| `monitoring_lan` | Bridged to LAN for scraping Node Exporter on other VMs |
| `db-gitea`       | Gitea ↔ PostgreSQL isolation                         |
| `db-umami`       | Umami ↔ PostgreSQL isolation                         |
| `ghost`          | Ghost ↔ MySQL isolation                             |

## Repository Structure

```
.
├── docker-compose.yaml          # Primary stack definition
├── compose.ghost.yaml           # Ghost + MySQL (included by main compose)
├── traefik/traefik.yml          # Traefik static configuration
├── letsencrypt/acme.json        # Certificate storage (placeholder)
├── prometheus/prometheus.yml    # Scrape targets
├── grafana/
│   ├── provisioning/            # Datasource and dashboard provider config
│   └── dashboards/              # Grafana dashboard JSON exports
├── loki/local-config.yaml       # Loki storage and ingestion config
├── promtail/config.yml          # Docker and journal log scraping
├── gitea-runner/config.yaml     # CI runner configuration
├── scripts/
│   ├── deploy-promtail.sh       # Install Promtail as a systemd service on VMs
│   └── deploy-node-exporter.sh  # Install Node Exporter as a systemd service on VMs
├── docs/Dockerfile              # Quartz container (internal docs)
└── quartz/Dockerfile            # Quartz container (public site)
```
