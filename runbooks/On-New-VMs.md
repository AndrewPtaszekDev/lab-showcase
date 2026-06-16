# New VM Provisioning Runbook

> Steps to provision a new VM and bring it under monitoring, backups, and lifecycle automation.
> For public showcase, internal addresses and usernames are `<PLACEHOLDERS>`

## 1. Create the VM
- Create a new VM via the Proxmox UI using **Ubuntu 22.04 LTS**

## 2. Initial OS Setup
- Log in and run updates:
```bash
sudo apt update && sudo apt upgrade -y
```

## 3. DNS Configuration
- Point the DNS to **PiHole** (`<DNS_SERVER_IP>`):
```
[Resolve]
DNS=<DNS_SERVER_IP>
FallbackDNS=1.1.1.1
DNSStubListener=no
```
* (If applicable) add the DNS record to the local DNS table in the **PiHole UI** (`http://<DNS_SERVER_IP>/admin/login`):

| example.your-domain.com | <NEW_VM_IP> |
| ----------------------- | ----------- |

## 4. Install QEMU Guest Agent for Temp Check
- In Proxmox UI: **VM → Options → QEMU Guest Agent → Enable**
```bash
sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```
- **(Optional)** Add a custom shutdown command to [[temp-monitor.sh]] (lives on the Proxmox host)

```bash
declare -A VM_CUSTOM_COMMANDS=(
	      [101]="cd /home/<USERNAME>/ && docker compose down && cd /home/<USERNAME>/minecraft && docker compose down"
    # [<NEW_VM_ID>]="systemctl stop myservice"
)
```

## 5. Add to [[keepalive-vms.sh]]
If the VM is critical to stay up (even if lab access is lost), add it to the VM list (script on the Proxmox host):
```bash
VMIDLIST=(100 101 <NEW_VM_ID>)
```

## 6. Deploy Monitoring Agents
Run the deployment scripts ([[deploy-promtail.sh]] & [[deploy-node-exporter.sh]]):
```bash
./deploy-promtail.sh
./deploy-node-exporter.sh
```
- Confirm Promtail is shipping logs (check Loki/Grafana)
- Confirm Node Exporter metrics are scraped (check Prometheus targets)

## 7. Add Prometheus Scrape Target
On the Prometheus host, add the new VM as a target under the `node_exporter` job in `prometheus.yml`:
```yaml
- job_name: node_exporter
  scrape_interval: 5s
  static_configs:
  - targets: ['<DNS_VM_IP>:9100']
    labels:
      instance: 'utils-vm'
  - targets: ['<PROXMOX_HOST_IP>:9100']
    labels:
      instance: 'lab'
  - targets: ['<DOCKER_VM_IP>:9100']
    labels:
      instance: 'docker-vm'
  - targets: ['<NEW_VM_IP>:9100']    # <-- add the new VM here
    labels:
      instance: '<new-vm-name>'
```
Reload Prometheus to pick up the change:
```bash
docker compose restart prometheus
```
- Verify the new target shows as **UP** at `http://<prometheus-host>:9090/targets`

## 8. UFW
```bash
sudo ufw allow 9100/tcp    # node-exporter
sudo ufw allow 9080/tcp    # promtail
sudo ufw enable
```

## 9. Automatic Security Updates
```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 10. NTP / Time Sync
Ensure the VM clock stays accurate:
```bash
sudo timedatectl set-timezone <YOUR_TIMEZONE>
timedatectl status
```

## 11. Add to Backups
- In Proxmox UI: **Datacenter → Backup → Add/Edit job**
- Include the new VM ID in the scheduled backup job

---

## Post-Setup Checklist
- [ ] VM created in Proxmox with Ubuntu 22.04 LTS
- [ ] DNS pointing to PiHole (`<DNS_SERVER_IP>`)
- [ ] QEMU Guest Agent installed and enabled
- [ ] Custom shutdown command configured (optional)
- [ ] Added to `keepalive-vms.sh` (optional)
- [ ] `deploy-promtail.sh` run — logs visible in Grafana
- [ ] `deploy-node-exporter.sh` run — metrics visible in Prometheus
- [ ] New scrape target added to `prometheus.yml` and showing UP
- [ ] Firewall rules applied
- [ ] Unattended upgrades enabled
- [ ] Time zone and NTP verified
- [ ] VM added to Proxmox backup schedule
