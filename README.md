# DevOps Monitoring Stack

A Docker Compose-based monitoring and centralized logging stack built as part of a STEP IT Academy team diploma project.

## My contribution

- Configured Linux servers for GitLab, application and production workloads.
- Deployed and maintained Docker Compose services.
- Configured Prometheus monitoring across multiple hosts.
- Built Grafana dashboards.
- Configured Loki and Promtail for centralized log collection.
- Integrated Node Exporter, cAdvisor and MySQL Exporter.
- Configured Nginx as the external HTTPS entry point.

## Architecture

```text
Linux hosts and Docker containers
        |                    |
   Node Exporter          Promtail
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
| Grafana | Dashboards | Internal Docker network |
| Prometheus | Metrics storage and scraping | Internal Docker network |
| Loki | Log storage | Internal Docker network |
| Promtail | Log shipping | Internal Docker network |
| Node Exporter | Host metrics | Internal Docker network |
| cAdvisor | Container metrics | Internal Docker network |
| MySQL | Database | Internal Docker network |
| MySQL Exporter | MySQL metrics | Internal Docker network |
| MinIO | Object storage / backup target | Internal Docker network |

Only Nginx publishes host ports in the Compose file. Services that need to be reached from other hosts (for example, exporters on monitored machines) must be exposed on their respective hosts and restricted by firewall rules to the monitoring network.

## Configuration

1. Install Docker Engine and the Docker Compose plugin.
2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
3. Replace every placeholder in `.env` with strong, unique credentials. Never commit `.env`.
4. Configure the MySQL Exporter account in MySQL with only the monitoring privileges it needs, then set its DSN in `.env`.
5. Review `prometheus.yml` and replace example/private host addresses with the addresses of your own monitored hosts.
6. Ensure the firewall allows only the required monitoring traffic from the monitoring host.
7. Start the stack:
   ```bash
   docker compose up -d
   ```

Docker Compose reads `.env` for variable substitution. The `.env.example` file contains placeholders only and is safe to commit.

## Backups

The `backup.sh` script dumps the configured database from the running MySQL container and uploads the dump using a preconfigured MinIO Client alias.

Configure the `mc` alias and bucket before running the script. Optional settings:

- `BACKUP_DIR` — local temporary backup directory (default: `./backups`).
- `BACKUP_BUCKET_PATH` — MinIO alias and bucket path (default: `local/mysql-backups`).
- `BACKUP_DATABASE` — database name (default: `sto_prod`).

The script removes its local temporary dump after the upload command succeeds. A successful upload is not a substitute for periodically testing database restores.

## Security notes

- Credentials are supplied through environment variables; use a private, untracked `.env` file on the host.
- Rotate any credentials that were previously committed if they were ever used outside a disposable test environment.
- Removing a secret from the current file does not remove it from Git history. If a committed credential was real, rotate it and consider rewriting repository history.
- Keep the Docker socket mount for Promtail protected: access to the Docker socket is effectively highly privileged.
- Pin image versions and review updates before using this educational stack in production.

## Project structure

```text
docker-compose.yml
prometheus.yml
loki-config.yaml
promtail-config.yaml
backup.sh
.env.example
grafana/
nginx/
```

## Disclaimer

This is an educational project. Validate configuration, firewall rules, credentials, backup uploads and restore procedures in your own environment before production use.
