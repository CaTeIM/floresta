# Floresta Bitcoin Node - ARM64 Docker 🌳₿🐳

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/CaTeIM/floresta-docker/build.yml?branch=main&style=for-the-badge)
![Docker Hub Pulls](https://img.shields.io/docker/pulls/cateim/floresta?style=for-the-badge)
![Docker Image Size](https://img.shields.io/docker/image-size/cateim/floresta/latest?style=for-the-badge)

*[🇺🇸 Read in English](README.md)*

Build automatizado `arm64` para o full node Bitcoin [Floresta](https://github.com/getfloresta/floresta). 

Esta imagem compila o node a partir do código-fonte oficial com a feature de **métricas habilitada**, permitindo o monitoramento detalhado do nó via Prometheus e Grafana nativamente.

## 📂 Estrutura de Diretórios no Servidor

Este setup foi desenhado para rodar no diretório `/srv/floresta/` no host. Antes de subir o stack, crie as pastas necessárias:

```bash
mkdir -p /srv/floresta/config
mkdir -p /srv/floresta/utreexo
mkdir -p /srv/floresta/metrics/prometheus
mkdir -p /srv/floresta/metrics/grafana
```

## 📄 Arquivos de Configuração Necessários

Crie os arquivos abaixo dentro das pastas que você acabou de criar no servidor.

**1. Arquivo de configuração do Floresta** (pode ficar vazio no início, serve para o Docker não criar um diretório no lugar do arquivo):
`/srv/floresta/config/floresta.toml`
```bash
touch /srv/floresta/config/floresta.toml
```

**2. Configuração do Prometheus:**
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

**3. Configuração de Fonte de Dados do Grafana:**
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

## 🚀 Subindo o Stack

Crie o seu arquivo `docker-compose.yml` raiz no servidor:
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

Inicie os serviços:

```bash
cd /srv/floresta
docker compose pull
docker compose up -d
```

## 📊 Acessos e Portas

* **Electrum Server:** `50001`
* **RPC Server:** `8332`
* **Métricas Internas:** `3333`
* **Grafana Dashboard:** `http://<IP-DO-SERVIDOR>:3000` 
  * **Usuário:** `admin`
  * **Senha:** `grafana`
