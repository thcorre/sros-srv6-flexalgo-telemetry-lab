# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Overview
This repository defines a containerlab-based Nokia SR OS lab that demonstrates SRv6 Flex-Algorithm (Algo 128) path selection using dynamic link delay (TWAMP-Light / STAMP) as a metric. It includes a telemetry pipeline (gnmic -> Prometheus -> Grafana) and helper scripts to generate traffic and manipulate link delays.

Prerequisites
- Docker
- containerlab >= 0.57.5
- Nokia vr-sros 23.10.R6 image available locally and a valid SR OS license file at the repo root as `license-sros.txt`

Common commands
- Deploy the lab (explicit topology): `clab deploy --reconfigure -t srv6-flexalgo.clab.yml`
- Destroy the lab and cleanup: `clab destroy --cleanup -t srv6-flexalgo.clab.yml`
- Show node list and addresses: `clab inspect -t srv6-flexalgo.clab.yml`
- Access nodes:
  - SR OS routers via SSH (default creds on lab images): `ssh admin@clab-srv6-flexalgo-R1`
  - Linux clients via Docker: `docker exec -it clab-srv6-flexalgo-client1 bash`
- Traffic generation:
  - Start UDP traffic (iperf3): `./start_traffic.sh`
  - Stop traffic: `./stop_traffic.sh`
- Adjust link delay (netem):
  - Set delay: `containerlab tools netem set -n clab-srv6-flexalgo-R1 -i eth2 --delay 100ms`
  - Remove delay: `containerlab tools netem delete -n clab-srv6-flexalgo-R1 -i eth2`
- Telemetry UIs:
  - Grafana: http://localhost:3000 (anonymous access enabled; admin/admin also works)
  - Prometheus: http://localhost:9090/graph
- Service logs:
  - gnmic: `docker logs -f clab-srv6-flexalgo-gnmic`
  - Prometheus: `docker logs -f clab-srv6-flexalgo-prometheus`
  - Grafana: `docker logs -f clab-srv6-flexalgo-grafana`

Architecture and flow
- Topology (srv6-flexalgo.clab.yml)
  - Nodes: R1–R5 (kind: nokia_sros), client1, client2, gnmic, prometheus, grafana
  - Management network: `srv6-flexalgo`
  - Startup configs for routers under `configs/Rx/Rx.cfg`
  - client1/client2 provisioned with IPs and routes via `exec` in topology file
- Telemetry pipeline
  - gnmic (`configs/gnmic/gnmic-config.yaml`)
    - Auth: admin/admin; `insecure: true`; `encoding: bytes`
    - Subscriptions sampled every 5s: Base router interface stats & oper-state, VPRN 50 interface oper-state/stats, dynamic link delay, CPU/memory, IPv6 route table, BGP peers and VPNv4/v6 route counts
    - Event processors: trim path prefixes; map oper-state up/down to 1/0
    - Output: Prometheus at `/metrics` on port 9804
  - Prometheus (`configs/prometheus/prometheus.yaml`)
    - Scrapes gnmic on `clab-srv6-flexalgo-gnmic:9804` every 10s
  - Grafana (provisioned via `configs/grafana`)
    - Datasource -> `clab-srv6-flexalgo-prometheus:9090` (default)
    - Dashboards auto-provisioned from `configs/grafana/dashboards/`
    - Plugins installed via `GF_INSTALL_PLUGINS`: agenty-flowcharting-panel, cloudspout-button-panel; anonymous access enabled
- Traffic path and FlexAlgo
  - `client1` -> `client2` over EVPN IFL service in VPRN 50, transported via SRv6 base locator (Algo 0) and FlexAlgo 128 locators
  - Dynamic link delay (TWAMP-Light) influences path selection; adjust with netem per-link and observe in Grafana vs IPv6 route table

Editing and iterating
- Router configs: edit `configs/Rx/Rx.cfg` and run `clab deploy --reconfigure -t srv6-flexalgo.clab.yml` to reapply startup configs
- Telemetry subs: edit `configs/gnmic/gnmic-config.yaml` and restart gnmic (`docker restart clab-srv6-flexalgo-gnmic`) or redeploy
- Dashboards: edit `configs/grafana/dashboards/*.json`; restart Grafana if changes aren’t picked up (`docker restart clab-srv6-flexalgo-grafana`)

File pointers
- `srv6-flexalgo.clab.yml` — lab topology and services
- `configs/gnmic/gnmic-config.yaml` — gNMI subscriptions and Prometheus export
- `configs/prometheus/prometheus.yaml` — Prometheus scrape config
- `configs/grafana/datasources/datasource.yaml`, `configs/grafana/dashboards/*.json` — Grafana provisioning
- `start_traffic.sh`, `stop_traffic.sh` — iperf3 traffic helper scripts
- `configs/R1...R5/*.cfg` — SR OS startup configs

Notes
- Container names are prefixed `clab-srv6-flexalgo-`; use that when addressing containers and hostnames.
- If accessing from a remote machine, replace `localhost` with the containerlab host IP for Grafana and Prometheus.
