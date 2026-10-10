# DevBox — локальное окружение разработки (rootless Podman)

Набор инструментов для PHP-разработки: nginx, несколько версий PHP-FPM,
MySQL + PostgreSQL + Redis + Manticore, перехват почты (Mailpit), phpMyAdmin + Adminer.

Работает полностью **без sudo** (rootless podman), воспроизводимо на любом Linux:
`git clone && just up`.

## Панель управления

Веб-панель окружения: **http://localhost** (тёмная, SvelteKit; код в `panel/`).

- статус и логи всех контейнеров (follow-стрим), start/stop/restart
- логи окружения (`logs/nginx`, `logs/php*`, journal панели): просмотр, follow, скачивание
- ссылки и реквизиты инструментов (phpMyAdmin, Adminer, Mailpit) и подключений к БД
- список хостов + создание нового в один клик (с кнопкой Apply — перезапуск nginx)
- управление окружением: restart / rebuild / stop (с подтверждением)
- переключатель Xdebug

Работает как systemd user-service (`devbox-panel.service`, порт `PANEL_PORT`).
Установка/обновление: `just panel-install`; после правок кода: `just panel-restart`; логи: `just panel-logs`.
Прямой доступ в обход nginx (если окружение остановлено): http://localhost:8989.


## Требования

- Podman 5+ (rootless)
- docker compose v2 (провайдер для `podman compose`)
- just (менеджер задач)

### Первый запуск на новой машине

```bash
# сокет podman для rootless-режима
systemctl --user enable --now podman.socket

# переменная окружения (можно в ~/.bashrc)
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock

# just — статический бинарник, кладём в ~/.local/bin
curl -sL https://github.com/casey/just/releases/latest/download/just-1.40.0-x86_64-unknown-linux-musl.tar.gz \
  | tar xz -C ~/.local/bin just

# глобальный алиас box (управление из любого каталога)
cat >> ~/.bashrc <<'EOF'
alias box='just --justfile "$HOME/Workspace/Server/justfile" --working-directory "$HOME/Workspace/Server"'
EOF
```

Затем:

```bash
cp .env.example .env   # поправьте пароли при необходимости
just build             # собрать образы и запустить
```

## Управление — `just` / `box`

Внутри каталога окружения — `just` (см. `just --list`).
**Из любого места системы** — алиас `box` (добавляется в `~/.bashrc`):

```bash
box up          # запуск стека
box ps          # статус
box sh mysql    # интерактивная сессия
box logs php82  # логи
box             # список всех рецептов
```

| Команда | Действие |
|---|---|
| `just up` / `just down` | запуск / остановка стека |
| `just build` | полная пересборка образов |
| `just ps` | список контейнеров |
| `just logs php82` | логи контейнера |
| `just sh [service]` | интерактивная сессия; запуск из `hosts/<proj>/...` попадает в тот же каталог контейнера |
| `just run php82 "composer install"` | команда в контейнере |
| `just in php82 "php artisan migrate"` | команда в текущем каталоге (запускать из `hosts/<project>/...`) |
| `just host myproject [php80]` | создать новый хост |
| `just sync` | перегенерировать алиасы `*.dvl.to` (вебхуки между хостами) |
| `just sql` / `just psql` / `just redis` | CLI-клиенты БД |
| `just xdebug [debug\|off]` | включить/выключить Xdebug |


## HTTPS

Все хосты доступны и по https (`https://*.dvl.to`) — wildcard-сертификат
от локального CA (mkcert), лежит в `config/nginx/ssl/` (до 01.2029).
Новые хосты из `just host` получают 443 автоматически.

Доверие сертификату (один раз на машине):

```bash
# системное хранилище (curl, chrome и т.д.)
sudo cp ~/.local/share/mkcert/rootCA.pem /etc/pki/ca-trust/source/anchors/mkcert-rootCA.crt
sudo update-ca-trust

# Firefox (использует своё хранилище): Settings → Privacy & Security →
# Certificates → View... → Authorities → Import → ~/.local/share/mkcert/rootCA.pem,
# галочка "Trust this CA to identify websites"
```

### Смена зоны (HOST_ZONE в .env)

Зона учитывается скриптами и панелью, но после её смены нужно:

1. `just ssl` — перевыпустить wildcard-сертификат под новую зону (иначе https станет «нечестным»);
2. `just sync` — перегенерировать сетевые алиасы;
3. учтите: `server_name` в nginx.conf **существующих** хостов останется со старой зоной —
   правится только в новых хостах (или sed'ом по `hosts/*/nginx.conf`);
4. DNS-правило на хосте (`address=/dvl.to/127.0.0.1`) — под новую зону.

## ИИ-ассистент в проекте

Чтобы ИИ-агент (opencode, Claude и т.п.), работающий с конкретным сайтом, знал,
как пользоваться окружением (запуск php/composer, БД, почта, отладка):

1. Скопировать инструкцию окружения в проект:
   ```bash
   just ai myproject        # создаёт hosts/myproject/AI.md
   ```
2. Создать в каталоге проекта `hosts/myproject/AGENTS.md` с правилами самого
   проекта (стек, конвенции кода, как запускать тесты) и ссылкой на окружение:
   ```markdown
   Правила работы с окружением (контейнеры, БД, запуск команд) — в AI.md рядом.
   ```
3. Открыть проект (`hosts/myproject/`) в агенте — он прочитает оба файла.

`AI.md` в корне репозитория — эталон; при изменении окружения он обновляется
(см. `AGENTS.md`), после чего достаточно повторить `just ai <проект>`.

## Сервисы и порты

| Сервис | Порт | Заметки |
|---|---|---|
| nginx | 80, 443 | хосты `*.dvl.to` (http + https), панель на http://localhost |
| Panel | 8989 | http://localhost (через nginx) |
| phpMyAdmin | 8080 | http://localhost:8080 |
| Adminer | 8081 | http://localhost:8081 (MySQL и PostgreSQL) |
| Mailpit | 8025 (UI), 1025 (SMTP) | вся почта проектов перехватывается |
| MySQL 8.0 | 3306 | root / `MYSQL_ROOT_PASSWORD` |
| PostgreSQL 17 | 5432 | postgres / `POSTGRES_PASSWORD` |
| Redis 7 | 6379 | persistence в `./data/redis` |
| Manticore | 9306, 9308 | |
| PHP-FPM | 9080 (8.0), 9081 (8.2), 9082 (8.4) | |

Внутри сети контейнеры доступны по alias'ам: `mysql`/`db`, `postgres`/`pg`,
`redis`, `mailpit` (также `mailhog`), `php82` и т.д.

### Вебхуки между хостами (из контейнера в контейнер)

Все `<хост>.dvl.to` автоматически резолвятся изнутри сети на nginx —
проекты могут ходить друг на друга обычными URL (`http://other-project.dvl.to/webhook`).
Список алиасов генерируется в `docker-compose.aliases.yaml` скриптом
`scripts/sync-hosts.sh` из каталога `hosts/` (подключён через `COMPOSE_FILE` в `.env`).
При создании хоста через `just host` алиас обновляется сам; после ручных изменений
в `hosts/` выполните `just sync`.

### DNS на хосте

Чтобы `*.dvl.to` открывались в браузере без правки `/etc/hosts`, добавьте правило
в NetworkManager (однократно):

```bash
nmcli con mod "<ваше соединение>" ipv6.dns-options \
  && sudo tee /etc/NetworkManager/conf.d/dev-dns.conf <<'EOF'
[main]
dns=dnsmasq
EOF
echo 'address=/dvl.to/127.0.0.1' | sudo tee /etc/NetworkManager/dnsmasq.d/devbox.conf
sudo systemctl restart NetworkManager
```

Либо просто держите записи в `/etc/hosts`.

## Xdebug

Xdebug установлен во все PHP-образы, по умолчанию выключен (`XDEBUG_MODE=off` в `.env`).

**Включение:** `just xdebug debug` (выключение — `just xdebug off`).

**PhpStorm:** нажмите *Start Listening for PHP Debug Connections* (телефонная трубка),
поставьте брейкпоинт — Xdebug сам подключится на порт 9003. Ничего настраивать не нужно
(idekey = `PHPSTORM`, client уже указан в `config/php*/xdebug.ini`).

**CLI-отладка:** `just run php82 "env XDEBUG_MODE=debug php script.php"`.

**Zed:** нативной поддержки нет; расширение `debuglink` умеет DBGP (порт 9003),
но стабильность не гарантируется.

## Почта

В проектах указывайте SMTP: `mailpit:1025` (без авторизации).
Вся отправленная почта видна в http://localhost:8025.

## Создание хоста

```bash
just host myproject        # PHP 8.2 по умолчанию
just host legacy php80     # PHP 8.0
```

Создаёт `hosts/<name>/htdocs` и nginx-конфиг. Сайт: `http://<name>.dvl.to`.

## Структура

```
├── config/            # Dockerfile и конфиги сервисов (php, nginx, mysql, nodejs)
├── hosts/             # проекты: <host>/htdocs + <host>/nginx.conf
├── data/              # данные БД (mysql, postgres, redis, manticore, mailpit)
├── logs/              # логи сервисов
├── scripts/           # devbox-host.sh (создание хоста) и sync-hosts.sh (алиасы *.dvl.to)
├── justfile           # задачи управления
└── docker-compose.yaml
```

## Восстановление на новой машине

```bash
git clone <repo> && cd server
systemctl --user enable --now podman.socket
cp .env.example .env
just build
```

Данные БД не переносятся автоматически — делайте дампы (`just sql` / `just psql`).
