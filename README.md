# DevOps Monitoring Stack

A Docker Compose-based monitoring and centralized logging stack built as part of a STEP IT Academy team diploma project.

## My contribution

- Configured Linux servers for GitLab, application and production workloads.
- Deployed and maintained Docker Compose services.
- Configured Prometheus monitoring across multiple hosts.
- Built Grafana dashboards.
- Configured Loki and Grafana Alloy for centralized log collection.
- Integrated Node Exporter, cAdvisor and MySQL Exporter.
- Configured Nginx as the external HTTPS entry point.

## Architecture

```text
Linux hosts and Docker containers
        |                    |
   Node Exporter          Grafana Alloy
   cAdvisor               |
        |                 v
        v                Loki
    Prometheus             |
        \                 /
         v               v
             Grafana
                ^
                |
              Nginx
        (HTTP/HTTPS entry)
```

## Services

| Service | Purpose | Exposure |
|---|---|---|
| Nginx | HTTPS reverse proxy | Host ports 80 and 443 |
| Grafana | Dashboards | Internal Docker network, via Nginx |
| Prometheus | Metrics collection and TSDB storage (3 days / 2 GB) | Internal Docker network; persistent named volume |
| Loki | Log storage with TSDB index and seven-day retention | Internal Docker network |
| Grafana Alloy | Log collection and shipping | Internal Docker network; read-only host log mounts |
| Node Exporter | Host metrics | Internal Docker network on this host |
| cAdvisor | Container metrics | Internal Docker network on this host |
| MySQL | Database | Internal Docker network |
| MySQL Exporter | MySQL metrics | Internal Docker network |
| MinIO | Object storage / backup target | Host loopback only: 127.0.0.1:9000 and 127.0.0.1:9001 |

Nginx is the only publicly published service. MinIO is bound to loopback so a locally installed MinIO Client can upload backups without exposing MinIO to the network. Services on other monitored hosts (for example, Node Exporter and cAdvisor) must listen on their host interfaces and be restricted by firewall rules to the monitoring host.

## Configuration

1. Install Docker Engine and the Docker Compose plugin.
2. Copy the example environment file (the default database name is `sto_prod`):
   ```bash
   cp .env.example .env
   ```
3. Replace every placeholder in `.env` with strong, unique credentials. For values used inside the MySQL Exporter DSN, use URL-safe alphanumeric secrets (for example, generate them with `openssl rand -hex 32`). Never commit `.env`.
4. Configure the MySQL Exporter account in MySQL with only the monitoring privileges it needs, then set its DSN in `.env`.
5. Review `prometheus.yml` and replace example/private host addresses with the addresses of your own monitored hosts.
6. Ensure the firewall allows only the required monitoring traffic from the monitoring host.
7. Ensure the TLS certificate and key exist at `nginx/ssl/fullchain.pem` and `nginx/ssl/privkey.pem`. These files must remain private and must not be committed.
8. Start the stack:
   ```bash
   docker compose config
   docker compose up -d
   ```

Docker Compose reads `.env` for variable substitution. The `.env.example` file contains placeholders only and is safe to commit.

## Backups

The `backup.sh` script dumps the configured database from the running MySQL container and uploads the dump using a preconfigured MinIO Client alias. The MinIO API is available on the host at `127.0.0.1:9000` only.

Configure the alias and bucket after creating `.env`:

```bash
set -a
. ./.env
set +a
mc alias set local http://127.0.0.1:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
mc mb --ignore-existing local/mysql-backups
```

Then run:

```bash
chmod +x backup.sh
./backup.sh
```

Optional settings:

- `BACKUP_DIR` — local temporary backup directory (default: `./backups`).
- `BACKUP_BUCKET_PATH` — MinIO alias and bucket path (default: `local/mysql-backups`).
- `BACKUP_DATABASE` — database name (default: `sto_prod`).

The script removes its local temporary dump after the upload command succeeds. A successful upload is not a substitute for periodically testing database restores.

## Security notes

- Credentials are supplied through environment variables; use a private, untracked `.env` file on the host.
- Rotate any credentials that were previously committed if they were ever used outside a disposable test environment.
- Removing a secret from the current file does not remove it from Git history. If a committed credential was real, rotate it and consider rewriting repository history.
- Grafana Alloy reads Docker JSON log files through a read-only `/var/lib/docker/containers` mount instead of accessing `/var/run/docker.sock`. This avoids granting Alloy Docker API control. The configuration assumes Docker's `json-file` logging driver; if the host uses another logging driver or a different data root, adjust the path and collection method.
- Alloy runs as root in the container so it can read host log files. Keep its mounts limited to the required log directories and do not expose its HTTP UI publicly.
- Pin image versions and review updates before using this educational stack in production.

## Project structure

```text
.
├── .github/
│   └── workflows/
│       ├── validate.yml
│       └── backup-restore.yml
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── prometheus.yml
├── nginx/
│   ├── nginx.conf
│   └── ssl/                 # private TLS files; not committed
├── .env.example
├── .gitignore
├── backup.sh
├── docker-compose.yml
├── loki-config.yaml          # TSDB v13, filesystem storage, 7-day retention
├── alloy-config.alloy
└── prometheus.yml
```

Prometheus stores TSDB data in the persistent `prometheus-data` Docker volume. Its configured retention is three days or 2 GB, whichever limit is reached first. The volume preserves metrics across container recreation; it is not a backup. Prometheus also scrapes its own `/metrics` endpoint. Scrape targets carry `host` and `role` labels so dashboards and queries can distinguish the monitoring, GitLab, application, production and database hosts. cAdvisor collection is intentionally limited to selected container CPU, memory, network and lifecycle metrics.

The former Promtail configuration has been replaced by `alloy-config.alloy`. Alloy persists its read positions and state under the ignored `alloy-data/` directory. Docker container logs are tailed from the host's `json-file` log paths; the Docker socket is not mounted.

## Continuous integration

GitHub Actions runs two workflows on pushes to `main` and `security-hardening`, and on pull requests targeting `main`:

- **Validate monitoring stack** checks Docker Compose interpolation, the Prometheus configuration, the Loki configuration, the Grafana Alloy configuration, the Nginx configuration (using a temporary self-signed certificate), and the backup script's Bash syntax.
- **Backup and restore integration test** starts disposable MySQL and MinIO containers, runs `backup.sh`, restores the SQL dump into a fresh MySQL container, and verifies a known test record.

These workflows validate configuration and the backup/restore script in an isolated CI environment. They do not deploy the stack or verify production server, firewall, TLS, or persistent-storage settings.

## Disclaimer

This is an educational project. Validate configuration, firewall rules, credentials, backup uploads and restore procedures in your own environment before production use.
