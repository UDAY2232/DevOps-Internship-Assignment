#!/bin/bash
set -euo pipefail

# TypeScript worker setup: installs Node.js, dependencies and starts the TS service
REPO_DIR=/opt/devops-assignment
APP_DIR=${REPO_DIR}/app/workers/ts-worker
ENV_FILE=/etc/devops-assignment.env

apt-get update
apt-get install -y curl git build-essential

# Install Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

useradd -m -s /bin/bash devops || true

mkdir -p ${REPO_DIR}
chown devops:devops ${REPO_DIR}

cd ${APP_DIR}
npm install --production || true

cat > ${ENV_FILE} <<EOF
TS_WORKER_PORT=9002
PYTHON_WORKER_HOST=${PYTHON_WORKER_IP:-10.10.0.11}
PYTHON_WORKER_PORT=9001
MODEL_WORKER_HOST=${MODEL_WORKER_IP:-10.10.0.13}
MODEL_WORKER_PORT=9003
REPO_DIR=${REPO_DIR}
PATH=/usr/bin:/bin
EOF

chown devops:devops ${ENV_FILE}
chmod 640 ${ENV_FILE}

if [ -f "${REPO_DIR}/systemd/ts-worker.service" ]; then
  cp ${REPO_DIR}/systemd/ts-worker.service /etc/systemd/system/ts-worker.service
  systemctl daemon-reload
  systemctl enable --now ts-worker.service
fi

echo "TS worker setup complete"
