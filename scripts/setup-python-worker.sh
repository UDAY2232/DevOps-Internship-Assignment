#!/bin/bash
set -euo pipefail

# Python worker setup: installs FastAPI server that acts as RPC endpoint
REPO_DIR=/opt/devops-assignment
APP_DIR=${REPO_DIR}/app/workers
ENV_FILE=/etc/devops-assignment.env

apt-get update
apt-get install -y python3 python3-venv python3-pip git curl

useradd -m -s /bin/bash devops || true

mkdir -p ${REPO_DIR}
chown devops:devops ${REPO_DIR}

# virtualenv and deps
python3 -m venv /opt/devops-worker-venv
/opt/devops-worker-venv/bin/pip install --upgrade pip
/opt/devops-worker-venv/bin/pip install fastapi uvicorn[standard] requests

# environment
cat > ${ENV_FILE} <<EOF
PYTHON_WORKER_PORT=9001
TS_WORKER_HOST=${TS_WORKER_IP:-10.10.0.12}
TS_WORKER_PORT=9002
MODEL_WORKER_HOST=${MODEL_WORKER_IP:-10.10.0.13}
MODEL_WORKER_PORT=9003
REPO_DIR=${REPO_DIR}
PATH=/opt/devops-worker-venv/bin:/usr/bin:/bin
EOF
chown devops:devops ${ENV_FILE}
chmod 640 ${ENV_FILE}

# copy systemd unit
if [ -f "${REPO_DIR}/systemd/python-worker.service" ]; then
  cp ${REPO_DIR}/systemd/python-worker.service /etc/systemd/system/python-worker.service
  systemctl daemon-reload
  systemctl enable --now python-worker.service
fi

echo "Python worker setup complete"
