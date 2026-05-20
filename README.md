# DevOps Assignment — Production-ready Quickstart

This repository contains a full production-style implementation for the DevOps internship assignment. It provisions GCP infrastructure (VPC, private subnet, firewall, compute instances), deploys an API gateway VM (public) and three private workers (Python, TypeScript, Model), wires RPC over private networking, and provides deployment automation, systemd services, and documentation.

**Contents**
- Terraform: `terraform/` — infrastructure-as-code for GCP
- Scripts: `scripts/` — VM bootstrap scripts executed at startup
- Systemd: `systemd/` — production-ready service units
- App: `app/` — API and worker code
- Diagrams: `diagrams/architecture.md`

**Quick TL;DR**
- Only the API gateway VM has a public IP.
- Workers run on private-only VMs and communicate via internal RPC (HTTP JSON).
- Everything is reproducible via Terraform + startup scripts.

**Architecture**
See `diagrams/architecture.md` for the mermaid diagram.

VM Layout and Private Networking
- API Gateway VM — public IP, serves FastAPI HTTP JSON `/infer` endpoint.
- Python Worker VM — private 10.10.0.11, exposes `/rpc` for internal RPC.
- TypeScript Worker VM — private 10.10.0.12, exposes `/rpc` and forwards to model worker.
- Model Worker VM — private 10.10.0.13, runs inference at `/infer`.

Network Design
- A VPC with a single private subnet `10.10.0.0/24` hosts all VMs.
- Firewall rules allow internal traffic within the subnet and expose HTTP/S only to the `api-gateway` tag.
- SSH access to API gateway is limited to the `ssh_cidr` defined in `terraform.tfvars`.

Terraform Setup
1. Install Terraform and configure GCP credentials (ADC) locally.
2. Edit `terraform/terraform.tfvars` with your `project_id`, `repo_url`, and `ssh_cidr`.
3. Initialize and apply:

```bash
cd terraform
terraform init
terraform apply -var-file=terraform.tfvars
```

Notes:
- `repo_url` should point to a public repo containing this project; instances will clone it on startup.

Deployment Steps (what the Terraform does)
- Creates VPC and private subnet.
- Reserves a static external IP for the API VM.
- Creates four compute instances with fixed private IPs.
- Each instance runs a metadata startup script that clones the repo and executes the appropriate `scripts/setup-*.sh`.

Service Startup
- Services are installed to `/etc/systemd/system/*.service` by the setup scripts and started automatically.
- Use `systemctl status api` (on API VM) or `systemctl status python-worker` (on Python worker) to check.

API Usage
- Endpoint: `POST http://<API_PUBLIC_IP>:8080/infer`
- Sample request:

```json
{
  "text": "Hello"
}
```

- Sample response:

```json
{
  "response": "Hi there! (processed: Hello [from-python] [from-ts])"
}
```

curl example

```bash
API_IP=$(terraform output -raw api_public_ip)
curl -s -X POST "http://${API_IP}:8080/infer" -H "Content-Type: application/json" -d '{"text":"Hello"}'
```

Troubleshooting
- If instances fail to configure, SSH to the API gateway (allowed CIDR) and check `/var/log/syslog` and `journalctl -u api`.
- Ensure `repo_url` is reachable and points to this repository; startup scripts clone and run `scripts/*.sh`.

Security Considerations & Production Hardening
- HTTPS: use a TLS certificate (managed cert or Let's Encrypt) on the API gateway (terminate TLS at the gateway).
- IAM roles: grant least-privilege service accounts to instances; avoid users' broad roles.
- Secrets: use Secret Manager or HashiCorp Vault; do not store secrets in plaintext or Git.
- Rate limiting: apply request throttling at the API gateway (FastAPI middleware, or cloud load balancer + Cloud Armor).
- Monitoring: install Prometheus exporters (node_exporter, process_exporter) and configure alerting.
- Centralized logging: forward logs to Stackdriver/Cloud Logging.
- Autoscaling: use managed instance groups or Kubernetes for worker pools.
- Health checks: implement /health for each service and configure load balancer health checks.
- CI/CD: use GitHub Actions / Cloud Build to run tests and deploy Terraform via pipelines.
- Kubernetes migration: for heavy workloads, move workers to GKE and use autoscaling and GPU node pools.

Scaling Strategy for 100x larger model
- Use GPU-enabled nodes (NVIDIA GPUs) in a dedicated node pool.
- Use model sharding and model-parallel inference (vLLM, TGI) to split large models across GPUs.
- Batch inference and request queueing (Redis, RabbitMQ, or Kafka) to improve throughput.
- Move to Kubernetes with Horizontal Pod Autoscaler and custom metrics for GPU utilization.
- Use object storage (GCS) for model artifacts and caching systems for embeddings.

Future improvements
- Add mutual TLS for internal RPC between workers.
- Replace simple HTTP RPC with gRPC for typed contracts and performance.
- Add central observability with OpenTelemetry.

Local Docker Compose simulation
 - The `docker-compose.yml` file runs a local simulation where:
   - `api` service is published to `localhost:8080` (public-facing)
   - `python-worker`, `ts-worker`, and `model-worker` run on an internal Docker network and are not exposed to the host
 - This mirrors the production network design where only the API gateway has a public endpoint.

Quick local run
```bash
# from repository root
docker compose build
docker compose up -d

# test the API locally
curl -s -X POST "http://localhost:8080/infer" -H "Content-Type: application/json" -d '{"text":"Hello"}' | jq .

# stop and remove
docker compose down
```

This provides a zero-cost way to demo the assignment without provisioning cloud resources.
