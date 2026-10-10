# AGENTS.md — правила для ИИ-агентов, дорабатывающих это окружение

Этот файл — про разработку и сопровождение самой среды DevBox.
Для работы с проектами хостов см. `AI.md` (копируется в каталог проекта).

1. **Rootless.** Команды с `sudo` не использовать. Любой podman/compose:
   ```bash
   export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
   cd ~/Workspace/Server
   ```
2. **Настройки — в `.env`.** Любая важная/изменяемая настройка (порты, пароли, режимы,
   зоны, версии по умолчанию) выносится в `.env` с дефолтом в `docker-compose.yaml`
   (`${VAR:-default}`) и дефолтной записью в `.env.example`.
3. **Синхронизация документации.** После любого изменения окружения
   (сервисы, порты, compose, скрипты, justfile, образы, сетевая схема, грабли)
   обновлять оба документа:
   - `README.md` — документация для человека;
   - `AI.md` — инструкция для агентов, работающих с проектами хостов.
   Изменение считается завершённым только когда оба файла отражают актуальное состояние.
4. **Интерфейс управления — justfile** (`just --list`). Новые операции добавлять
   рецептами туда, а не отдельными скриптами; скрипты в `scripts/` — только то,
   что слишком крупное для рецепта (`devbox-host.sh`, `sync-hosts.sh`).

## Схема среды (кратко)

- Сервисы: nginx, php80/82/84 (+`php-fpm -R`, пулы от root: контейнерный root = uid хоста),
  mysql, postgres, redis, manticore, mailpit, phpmyadmin, adminer, nodejs.
- **Панель управления**: `panel/` (SvelteKit + Tailwind), systemd user-service
  `devbox-panel.service`, http://localhost (nginx default_server → хост:8989).
  Конвенции панели — `panel/AGENTS.md`. После правок: `just panel-restart`.
- `hosts/<proj>/` ↔ `/var/www/<proj>/`; vhost = `hosts/<proj>/nginx.conf` (http+https, mkcert).
- Алиасы `*.dvl.to` для сети генерирует `scripts/sync-hosts.sh` → `docker-compose.aliases.yaml`
  (подключён через `COMPOSE_FILE`); после правок `hosts/` — `just sync`.
- SSL: `config/nginx/ssl/` (mkcert, до 2029), CA — `~/.local/share/mkcert/rootCA.pem`.
- Данные сервисов — `data/*`, логи — `logs/*`.

## Грабли, которые уже наступлены

- nginx кэширует IP php-upstream: после пересоздания php — `podman compose restart nginx`
  (`just up` делает сам).
- php:8.0 образ — bullseye, пакеты из `archive.debian.org` (sed-блок в Dockerfile обязателен).
- MySQL-данные нельзя переносить из rootful-эпохи без chown на uid пользователя.
