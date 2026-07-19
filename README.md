# DevOps Monitoring Stack

Production-style monitoring and centralized logging stack.

## My Contribution

This project was completed as part of a STEP IT Academy team diploma project.

My responsibilities included:

- Configured and maintained Linux servers (GitLab, App and Production).
- Deployed and configured Docker Compose services.
- Configured Prometheus monitoring for multiple servers.
- Created and configured Grafana dashboards.
- Configured Loki and Promtail for centralized log collection.
- Configured Node Exporter, cAdvisor and MySQL Exporter.
- Configured Nginx log collection.
- Verified communication between monitored servers and the monitoring stack.

# Features

- Infrastructure monitoring

- Docker containers monitoring

- Centralized logging with Loki

- Real-time log aggregation

- Multi-host monitoring

- MySQL metrics

- Nginx logs

- Docker metrics with cAdvisor

- System metrics with Node Exporter

---

# Architecture

Servers & Containers
        ↓
Exporters & Promtail
        ↓
Prometheus + Loki
        ↓
Grafana Dashboards

---

# Monitored Servers

- db-monitor
- gitlab-server
- app-server
- prod-server

---

# Monitoring Stack

| Service | Port |
|---|---|
| Grafana | 3000 |
| Prometheus | 9090 |
| Loki | 3100 |
| Node Exporter | 9100 |
| cAdvisor | 8080 |
| MySQL Exporter | 9104 |

---

# Docker Services

- Grafana
- Prometheus
- Loki
- Promtail
- cAdvisor
- Node Exporter
- MySQL
- MySQL Exporter
- Nginx

---

# Project Structure

```bash
docker-compose.yml
prometheus.yml
loki-config.yaml
promtail-config.yaml

grafana/
nginx/
