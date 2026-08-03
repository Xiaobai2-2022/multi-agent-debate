#!/usr/bin/env bash

set -Eeuo pipefail

# Start vLLM services sequentially to avoid GPU-memory profiling races.
#
# Expected ports:
#   qwen-coder -> 8101
#   gpt-oss    -> 8103
#   deepseek   -> 8102

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

HEALTH_TIMEOUT_SECONDS="${HEALTH_TIMEOUT_SECONDS:-1200}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-5}"

declare -a SERVICES=(
  "qwen-coder:8101"
  "gpt-oss:8103"
  "deepseek:8102"
)

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

show_failure_logs() {
  local service="$1"

  log "Recent logs for ${service}:"
  docker compose logs --tail=120 "$service" || true
}

wait_for_health() {
  local service="$1"
  local port="$2"
  local elapsed=0
  local container_id=""

  log "Waiting for ${service} on port ${port}..."

  while (( elapsed < HEALTH_TIMEOUT_SECONDS )); do
    container_id="$(docker compose ps -q "$service" 2>/dev/null || true)"

    if [[ -z "$container_id" ]]; then
      log "ERROR: No container exists for ${service}."
      show_failure_logs "$service"
      return 1
    fi

    local status
    status="$(docker inspect \
      --format '{{.State.Status}}' \
      "$container_id" 2>/dev/null || true)"

    if [[ "$status" == "exited" || "$status" == "dead" ]]; then
      log "ERROR: ${service} container entered state: ${status}"
      show_failure_logs "$service"
      return 1
    fi

    if curl --silent --show-error --fail \
      --max-time 3 \
      "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
      log "${service} is ready."
      return 0
    fi

    sleep "$POLL_INTERVAL_SECONDS"
    elapsed=$((elapsed + POLL_INTERVAL_SECONDS))

    if (( elapsed % 60 == 0 )); then
      log "Still waiting for ${service}; elapsed ${elapsed}s."
    fi
  done

  log "ERROR: ${service} did not become ready within ${HEALTH_TIMEOUT_SECONDS}s."
  show_failure_logs "$service"
  return 1
}

show_memory() {
  log "Current CUDA allocations:"
  nvidia-smi \
    --query-compute-apps=pid,process_name,used_memory \
    --format=csv 2>/dev/null || true

  log "Current host memory:"
  free -h || true
}

cleanup_failed_service() {
  local service="$1"

  log "Stopping failed service: ${service}"
  docker compose stop "$service" >/dev/null 2>&1 || true
}

main() {
  log "Validating Docker Compose configuration..."
  docker compose config >/dev/null

  # Avoid old failed/restarting containers interfering with memory profiling.
  log "Stopping existing LLM containers..."
  docker compose stop qwen-coder gpt-oss deepseek >/dev/null 2>&1 || true

  for item in "${SERVICES[@]}"; do
    local service="${item%%:*}"
    local port="${item##*:}"

    log "Starting ${service}..."
    docker compose up -d --force-recreate "$service"

    if ! wait_for_health "$service" "$port"; then
      cleanup_failed_service "$service"
      exit 1
    fi

    show_memory
  done

  log "All LLM services are ready."

  docker compose ps

  printf '\nEndpoints:\n'
  printf '  Qwen Coder: http://127.0.0.1:8101/v1\n'
  printf '  GPT-OSS:    http://127.0.0.1:8103/v1\n'
  printf '  DeepSeek:   http://127.0.0.1:8102/v1\n'
}

main "$@"
