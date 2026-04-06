# Floresta Bitcoin Node - ARM64 Docker 🌳₿🐳

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/CaTeIM/floresta-docker/build.yml?branch=main&style=for-the-badge)
![Docker Hub Pulls](https://img.shields.io/docker/pulls/cateim/floresta?style=for-the-badge)
![Docker Image Size](https://img.shields.io/docker/image-size/cateim/floresta/latest?style=for-the-badge)

*[🇧🇷 Leia em Português](README.pt-br.md)*

Automated `arm64` Docker build for the [Floresta](https://github.com/getfloresta/floresta) Bitcoin full node. 

This image compiles the node from the official source code with the **metrics feature enabled**, allowing detailed node monitoring via Prometheus and Grafana natively.

## 📂 Server Directory Structure

This setup is designed to run in the `/srv/floresta/` directory on the host. Before deploying the stack, create the necessary folders:

```bash
mkdir -p /srv/floresta/config
mkdir -p /srv/floresta/utreexo
mkdir -p /srv/floresta/metrics/prometheus
mkdir -p /srv/floresta/metrics/grafana
```

## 📄 Required Configuration Files

Create the following files inside the directories you just created on your server.

**1. Floresta configuration file** (can be empty at first, just so Docker creates a file instead of a directory):
`/srv/floresta/config/floresta.toml`
```bash
touch /srv/floresta/config/floresta.toml
```

**2. Prometheus configuration:**
`/srv/floresta/metrics/prometheus/prometheus.yml`
```yaml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
scrape_configs:
  - job_name: prometheus
    honor_timestamps: true
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /
    scheme: http
    static_configs:
      - targets:
          - floresta:3333
```

**3. Grafana Datasource configuration:**
`/srv/floresta/metrics/grafana/datasource.yml`
```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
    access: proxy
    editable: true
```

## 🚀 Running the Stack

Create your root `docker-compose.yml` file on the server:
`/srv/floresta/docker-compose.yml`

```yaml
services:
  floresta:
    image: cateim/floresta:latest
    container_name: floresta
    command: florestad -c /data/config.toml --data-dir /data/.floresta
    ports:
      - 50001:50001
      - 8332:8332
      - 3333:3333
    volumes:
      - /srv/floresta/config/floresta.toml:/data/config.toml
      - /srv/floresta/utreexo:/data/.floresta
    restart: unless-stopped

  prometheus:
    image: prom/prometheus
    container_name: prometheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
    ports:
      - 9090:9090
    restart: unless-stopped
    volumes:
      - /srv/floresta/metrics/prometheus:/etc/prometheus

  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - 3000:3000
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=grafana
    volumes:
      - /srv/floresta/metrics/grafana:/etc/grafana/provisioning/datasources
      - /srv/floresta/metrics/grafana:/var/lib/grafana
```

Start the services:

```bash
cd /srv/floresta
docker compose pull
docker compose up -d
```

## 📊 Access and Ports

* **Electrum Server:** `50001`
* **RPC Server:** `8332`
* **Internal Metrics:** `3333`
* **Grafana Dashboard:** `http://<SERVER-IP>:3000` 
  * **User:** `admin`
  * **Password:** `grafana`
