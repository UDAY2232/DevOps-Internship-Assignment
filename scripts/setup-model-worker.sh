#!/bin/bash
set -euo pipefail

# Model worker setup: installs Python and model dependencies (lightweight dummy model here)
REPO_DIR=/opt/devops-assignment
APP_DIR=${REPO_DIR}/app/workers
ENV_FILE=/etc/devops-assignment.env

apt-get update
apt-get install -y python3 python3-venv python3-pip git curl

useradd -m -s /bin/bash devops || true

mkdir -p ${REPO_DIR}
chown devops:devops ${REPO_DIR}

# virtualenv and deps
python3 -m venv /opt/devops-model-venv
/opt/devops-model-venv/bin/pip install --upgrade pip
/opt/devops-model-venv/bin/pip install fastapi uvicorn[standard] numpy

cat > ${ENV_FILE} <<EOF
MODEL_WORKER_PORT=9003
REPO_DIR=${REPO_DIR}
PATH=/opt/devops-model-venv/bin:/usr/bin:/bin
EOF

chown devops:devops ${ENV_FILE}
chmod 640 ${ENV_FILE}

if [ -f "${REPO_DIR}/systemd/model-worker.service" ]; then
  cp ${REPO_DIR}/systemd/model-worker.service /etc/systemd/system/model-worker.service
  systemctl daemon-reload
  systemctl enable --now model-worker.service
fi

echo "Model worker setup complete"
