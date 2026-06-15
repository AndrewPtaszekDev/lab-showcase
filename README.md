# Homelab

Self-hosted infrastructure running on Proxmox, orchestrated with Docker Compose and fronted by Traefik.

> **Note:** This is a sanitized copy of a live configuration. All secrets, credentials, and private domains have been replaced with descriptive placeholders.

# Purpose & Goals
To create a self-directed learning environment. I've learned:
* Production-grade technologies
* System design and DevOps practices
* Automation and scripting
* Technical documentation design & teaching those concepts
* To create useful services for myself (like [this site](https://ptaszek.studio)!)
# Hardware 
* **CPU:** AMD Ryzen 9 5950X (16C / 32T, x86_64)
* **Memory:** 128GB (total) 
* **Storage:** 
	• 1x 2 TB NVMe SSD  
	• Proxmox VE default LVM layout  
	• 96 GB root volume, 8 GB swap  
	• 1.7 TB LVM-thin pool for VM disks
	* VM 100 disk: 16 GB 
	* VM 101 disk: 32 GB
* **Network**: Dual 1 GbE Ethernet NICs (1 active)
* **OS:** Proxmox VE 9.1 (Bare Metal)
# Architecture
## Network Topology
![[Lab Network Diagram.png]]
## Observability
![](images/New Monitoring Diagram Dark)
### GitOps
![](GitOps Diagram Public.png)
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
| Dockerized-Quartz | Site hosting + building | ptaszek.studio  | Container | Public (HTTP/S) |
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
| `db-umami`       | Umami ↔ PostgreSQL isolation                         |                          |
```
