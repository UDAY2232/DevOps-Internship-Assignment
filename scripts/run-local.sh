#!/bin/bash
set -euo pipefail

# Build and start the local Docker Compose stack, wait for API, run smoke test
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building images..."
docker compose build

echo "Starting services..."
docker compose up -d

API_URL="http://localhost:8080/infer"
MAX_RETRIES=30
SLEEP=2

echo "Waiting for API to become ready at ${API_URL}..."
i=0
while [ $i -lt $MAX_RETRIES ]; do
  if curl -sSf -X POST "$API_URL" -H "Content-Type: application/json" -d '{"text":"health"}' > /dev/null 2>&1; then
    echo "API is up"
    break
  fi
  i=$((i+1))
  sleep $SLEEP
done

if [ $i -eq $MAX_RETRIES ]; then
  echo "API did not become ready after $((MAX_RETRIES*SLEEP)) seconds" >&2
  docker compose logs --no-color api || true
  exit 1
fi

echo "Running smoke test and saving output to live_response.json"
curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d '{"text":"Hello from local demo"}' > live_response.json

echo "Smoke test result:" && cat live_response.json

echo "To stop the stack run: docker compose down"
