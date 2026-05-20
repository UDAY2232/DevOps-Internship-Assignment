#!/bin/bash
set -euo pipefail

# This script runs on the API gateway VM. It installs system dependencies,
# sets up Python, the FastAPI app, and the systemd service.

REPO_DIR=/opt/devops-assignment
APP_DIR=${REPO_DIR}/app/api
ENV_FILE=/etc/devops-assignment.env

apt-get update
apt-get install -y python3 python3-venv python3-pip git curl

# create service user
useradd -m -s /bin/bash devops || true

mkdir -p ${REPO_DIR}
chown devops:devops ${REPO_DIR}

if [ -d "${REPO_DIR}" ] && [ -d "${REPO_DIR}/app" ]; then
  echo "Repository already present"
else
  # repo is cloned by metadata startup script
  echo "Repository should be at ${REPO_DIR}"
fi

# create virtualenv and install
python3 -m venv /opt/devops-venv
/opt/devops-venv/bin/pip install --upgrade pip
/opt/devops-venv/bin/pip install fastapi uvicorn[standard] httpx pydantic

# Write environment file consumed by systemd service
cat > ${ENV_FILE} <<EOF
PYTHON_WORKER_HOST=${PYTHON_WORKER_IP:-10.10.0.11}
PYTHON_WORKER_PORT=9001
TS_WORKER_HOST=${TS_WORKER_IP:-10.10.0.12}
TS_WORKER_PORT=9002
MODEL_WORKER_HOST=${MODEL_WORKER_IP:-10.10.0.13}
MODEL_WORKER_PORT=9003
REPO_DIR=${REPO_DIR}
PATH=/opt/devops-venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF

chown devops:devops ${ENV_FILE}
chmod 640 ${ENV_FILE}

# Install app dependencies if requirements file exists
if [ -f "${APP_DIR}/requirements.txt" ]; then
  /opt/devops-venv/bin/pip install -r ${APP_DIR}/requirements.txt
fi

# Install the api systemd unit from repo
if [ -f "${REPO_DIR}/systemd/api.service" ]; then
  cp ${REPO_DIR}/systemd/api.service /etc/systemd/system/api.service
  systemctl daemon-reload
  systemctl enable --now api.service
fi

echo "API setup complete"
