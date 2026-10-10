#!/bin/bash
# Генерирует docker-compose.aliases.yaml: все hosts/<name> получают
# алиас <name>.<HOST_ZONE> в сети контейнеров (указывает на nginx).
# Нужно для вебхуков/запросов между хостами изнутри контейнеров.
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

[ -f .env ] || { echo "Ошибка: .env не найден" >&2; exit 1; }
source .env
HOST_ZONE="${HOST_ZONE:-dvl.to}"

OUT="docker-compose.aliases.yaml"
{
  echo "# Автогенерация scripts/sync-hosts.sh — не редактировать вручную"
  echo "services:"
  echo "  nginx:"
  echo "    networks:"
  echo "      app-network:"
  echo "        aliases:"
  for dir in hosts/*/; do
    name="$(basename "$dir")"
    [ -f "$dir/nginx.conf" ] || continue
    echo "          - ${name}.${HOST_ZONE}"
  done
} > "$OUT"

COUNT=$(grep -c '          - ' "$OUT")
echo "Сгенерирован $OUT: $COUNT алиасов *.$HOST_ZONE"
echo "Применение: podman compose up -d nginx (пересоздаст контейнер с новыми алиасами)"
