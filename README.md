# Enterprise Infrastructure Lab

Self-hosted infrastructure **showcase** running on Proxmox, orchestrated with Docker Compose and fronted by Traefik. _Secrets are replaced by placeholders._

> **Operational resilience**
> Self-hosted version control, comprehensive runbooks & documentation [(see examples)](runbooks/), automatic offsite backups & repo mirroring.

> **Full-stack observability**
> Prometheus metrics, Grafana dashboards, Loki + Promtail log aggregation, per-container resource tracking via cAdvisor, and user service ingress analytics dashboards.

> **Layered security**
> Segmented Docker networks isolate databases, monitoring, & public services. Traefik terminates TLS Let's Encrypt certs. Sensitive dashboards sit behind VPN-only access with basic auth.

I especially enjoyed creating the technical articles that I used to teach these concepts via workshops at my university. [See them here](https://ptaszek.studio/Lab)

<img width="1171" height="651" alt="Grafana-Showcase" src="https://github.com/user-attachments/assets/5f4ada9b-fb07-4480-acf8-eea6610349b3" />

# Purpose & Lessons
I wanted to create a self-directed learning environment. I've learned:
* Production-grade technologies
* System design and DevOps practices
* Automation and scripting
* Technical documentation design & teaching those concepts via workshops
* To deploy useful services for myself (like [my website](https://ptaszek.studio)!)

# Architecture

## Overview
![Lab Archictecture Diagram](images/Lab-Architecture-Showcase)

## Observability
![Observability Diagram](images/Monitoring-Diagram)

### GitOps
![GitOps Diagram](images/GitOps-Diagram)

# Services

### Core Infrastructure
| Service | Purpose                 | URL/Access       | Stack      | Exposure     |
| ------- | ----------------------- | ---------------- | ---------- | ------------ |
| Proxmox | Virtualization          | 10.0.0.10        | Bare metal | LAN          |
| PiVPN   | VPN                     | x.ptaszek.studio | VM         | Public (UDP) |
| PiHole  | DNS server + AD blocker | 10.0.0.159       | VM         | LAN          |
| Traefik | Reverse-proxy           | 10.0.0.206:8080  | Container  | LAN          |
### User Services
| Service           | Purpose                 | URL/Access      | Stack     | Exposure        |
| ----------------- | ----------------------- | --------------- | --------- | --------------- |
| Dockerized-Quartz | Site hosting + building | [ptaszek.studio](https://ptaszek.studio)  | Container | Public (HTTP/S) |
| Calibre web       | E-book management       | 10.0.0.206:8083 | Container | Internal        |
### Observability
| Service       | Purpose                      | URL/Access             | Stack     | Exposure        |
| ------------- | ---------------------------- | ---------------------- | --------- | --------------- |
| Prometheus    | Metrics aggregation          | prometheus:9090        | Container | LAN             |
| Grafana       | Dashboards                   | grafana.ptaszek.studio | Container | Public (HTTP/S) |
| Loki          | Logs aggregation             | loki:3100              | Container | LAN             |
| Promtail      | Log shipper                  | —                      | Systemd   | LAN             |
| Node Exporter | Metrics shipper              | —                      | Systemd   | LAN             |
| cAdvisor      | Container Metrics Collection | cAdvisor:8080          | Container | Internal        
### Docs & Version Control
| Service      | Purpose            | URL/Access          | Stack     | Exposure        |
| ------------ | ------------------ | ------------------- | --------- | --------------- |
| Gitea        | Version control    | gitea:3000          | Container | Internal        |
| Gitea-runner | Gitea CI/CD        | —                   | Container | Internal        |
| Postgres     | Gitea database     | postgres:5432       | Container | Internal        |
| Quartz-docs  | Documentation site | docs.ptaszek.studio | Container | Public (HTTP/S) 

## Networking

| Network          | Purpose                                              |
|------------------|------------------------------------------------------|
| `proxy`          | Traefik ↔ public-facing services                     |
| `monitoring`     | Internal-only bridge for the observability stack      |
| `monitoring_lan` | Bridged to LAN for scraping Node Exporter on other VMs |
| `db-gitea`       | Gitea ↔ PostgreSQL isolation                         |
| `db-umami`       | Umami ↔ PostgreSQL isolation                         | 
