#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

DEPLOY_HOST="${DEPLOY_HOST:-213.165.209.126}"
DEPLOY_USER="${DEPLOY_USER:-solidlsnake}"
SSH_KEY="${SSH_KEY:-${HOME}/Downloads/ssh-key-1775223951800/ssh-key-1775223951800}"
REMOTE_APP_DIR="${REMOTE_APP_DIR:-wtf_yandex_sirius}"

SSH_OPTS=(
  -i "$SSH_KEY"
  -o StrictHostKeyChecking=accept-new
  -o ConnectTimeout=30
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=8
  -o TCPKeepAlive=yes
)
SSH=(ssh "${SSH_OPTS[@]}")
RSYNC_RSH="ssh $(printf '%q ' "${SSH_OPTS[@]}")"
RSYNC_RSH="${RSYNC_RSH% }"

if [[ ! -f "$SSH_KEY" ]]; then
  echo "Нет ключа: $SSH_KEY — задай SSH_KEY=..."
  exit 1
fi
chmod 600 "$SSH_KEY" 2>/dev/null || true

echo "→ Проверка SSH ${DEPLOY_USER}@${DEPLOY_HOST}..."
"${SSH[@]}" "${DEPLOY_USER}@${DEPLOY_HOST}" "mkdir -p \"\$HOME/$REMOTE_APP_DIR\" && command -v docker >/dev/null && (docker compose version 2>/dev/null || sudo docker compose version)"

echo "→ Удаление старых артефактов Flutter/Xcode на сервере (если были после прошлых rsync)..."
"${SSH[@]}" "${DEPLOY_USER}@${DEPLOY_HOST}" \
  "rm -rf \"\$HOME/$REMOTE_APP_DIR/ios\" \"\$HOME/$REMOTE_APP_DIR/android\" \"\$HOME/$REMOTE_APP_DIR/linux\" \"\$HOME/$REMOTE_APP_DIR/macos\" \"\$HOME/$REMOTE_APP_DIR/windows\" \"\$HOME/$REMOTE_APP_DIR/web\" \"\$HOME/$REMOTE_APP_DIR/.dart_tool\" \"\$HOME/$REMOTE_APP_DIR/build\" 2>/dev/null || true"

echo "→ rsync: только backend + compose (без Flutter-проекта, быстро)..."
RSYNC=(rsync -avz --delete --partial -e "$RSYNC_RSH")

"${RSYNC[@]}" \
  "$ROOT/docker-compose.yml" \
  "$ROOT/docker-compose.prod.yml" \
  "${DEPLOY_USER}@${DEPLOY_HOST}:~/${REMOTE_APP_DIR}/"

"${RSYNC[@]}" \
  --exclude .env \
  "$ROOT/backend/" \
  "${DEPLOY_USER}@${DEPLOY_HOST}:~/${REMOTE_APP_DIR}/backend/"

echo "→ Сборка и запуск Docker..."
"${SSH[@]}" "${DEPLOY_USER}@${DEPLOY_HOST}" bash -s <<EOF
set -e
cd "\$HOME/$REMOTE_APP_DIR"
if [[ ! -f .env ]]; then
  echo "JWT_SECRET=\$(openssl rand -hex 32)" > .env
  echo "Создан .env с JWT_SECRET на сервере"
fi
if docker info >/dev/null 2>&1; then
  docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env up -d --build
  docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
else
  sudo docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env up -d --build
  sudo docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
fi
EOF

echo "Готово. API: http://${DEPLOY_HOST}:8080"
echo "В приложении: flutter run --dart-define=API_BASE_URL=http://${DEPLOY_HOST}:8080"
