# Offsite GitHub Repo Restore

All self-hosted Gitea repos have a GitHub offsite push mirror. If a repo is corrupted or lost, all of these files (and their versioned history) can be restored.

## Restore via Gitea Migration (Web UI)
Gitea's built-in migration tool can import directly from GitHub.

1. Log in to Gitea as an admin or the target repo owner.
2. Click **+ → New Migration**.
3. Select **GitHub** as the source.
4. Fill in the migration form:

| Field | Value |
| ---------------- | ----- |
| Clone Address | `https://github.com/<GITHUB_USER>/<repo>.git` |
| Access Token | Your GitHub PAT (required for private repos) |
| Owner | The Gitea user or organization to own the restored repo |
| Repository Name | Use the original name |

5. Click **Migrate Repository** and wait.
6. Verify the restored repo: check branches, tags, and recent commit history.

### Re-enable the push mirror
If the Gitea instance is back in service and you want to continue mirroring:

1. Open the repo in Gitea → **Settings → Repository → Mirror Settings**.
2. Add a new push mirror pointing to the same GitHub remote:

```
https://<GITHUB_USER>:<GITHUB_TOKEN>@github.com/<GITHUB_USER>/<repo>.git
```

* Set the sync interval (e.g., every 8 hours).
* Click **Add Push Mirror** and trigger a manual sync to confirm it works.

## Full Backup
For full VM backups, including volumes.

### Via the GUI

1. Log in to the Proxmox web interface (`http://<PROXMOX_HOST_IP>:8006`).
2. In the left panel, select `local` storage.
3. Click the **Backups** tab.
4. Locate the backup by VM ID, date, and timestamp.
5. Click **Restore**.

## Troubleshooting

**Restore fails with "storage not found"**
The backup may reference a storage ID that doesn't exist on this node. Use `--storage <target>` to redirect disks to an available storage.

**Restore fails with "VM already exists"**
Either destroy the existing VM first (`qm destroy <vmid>`) or choose a different VM ID for the restore.
