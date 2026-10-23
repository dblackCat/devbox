set dotenv-load

ROOT := justfile_directory()

# Движок: podman или docker. Берётся из ENGINE в .env, иначе автоопределение
engine := if env_var_or_default("ENGINE", "") != "" { env_var_or_default("ENGINE", "") } else { if `command -v podman 2>/dev/null || true` != "" { "podman" } else { "docker" } }

# Короткая справка: просто `just`
@default:
    @just --list

# Запуск всего стека (nginx перезапускается последним — обновляет IP php-fpm)
up:
    {{engine}} compose up -d && {{engine}} compose restart nginx

# Остановка стека
down:
    {{engine}} compose down

# Перезапуск контейнеров
@restart:
    just down && just up

# Полная пересборка образов
@build:
    {{engine}} compose build --no-cache && {{engine}} compose up -d

# Список контейнеров
ps:
    {{engine}} compose ps

# Логи контейнера: just logs php82
logs service:
    {{engine}} compose logs -f {{service}}

# Интерактивная сессия в контейнере с маппингом текущего каталога:
# запущенный из hosts/myproject/htdocs попадёт в /var/www/myproject/htdocs
[no-cd]
sh service="php82":
    #!/usr/bin/env bash
    CALLDIR="$PWD"; cd "{{ ROOT }}"
    workdir="/var/www"
    case "$CALLDIR" in */hosts/*) workdir="/var/www/${CALLDIR#*/hosts/}";; esac
    echo "Контейнер {{service}}, каталог: $workdir"
    {{engine}} compose exec -w "$workdir" {{service}} bash

# Команда в контейнере: just run php82 "php -v"  |  just run nodejs "npm install"
run service cmd:
    {{engine}} compose exec {{service}} bash -c "{{cmd}}"

# Команда в контейнере в текущем каталоге:
# из hosts/myproject: just in php82 "composer install"
[no-cd]
in service cmd:
    #!/usr/bin/env bash
    CALLDIR="$PWD"; cd "{{ ROOT }}"
    workdir="/var/www"
    case "$CALLDIR" in */hosts/*) workdir="/var/www/${CALLDIR#*/hosts/}";; esac
    {{engine}} compose exec -w "$workdir" {{service}} bash -c "{{cmd}}"

# Создание нового хоста: just host myproject php80
@host name php="php82":
    ./scripts/devbox-host.sh {{name}} {{php}}

# Перегенерировать алиасы *.dvl.to для вебхуков между хостами
@sync:
    ./scripts/sync-hosts.sh && {{engine}} compose up -d nginx

# Перевыпустить SSL-сертификат (wildcard текущей зоны из .env): just ssl [зона]
@ssl zone="":
    #!/usr/bin/env bash
    Z="{{zone}}"
    [ -z "$Z" ] && Z=$(grep '^HOST_ZONE=' .env | cut -d= -f2)
    Z="${Z:-dvl.to}"
    cd config/nginx/ssl
    rm -f dvl.to.pem dvl.to.key _wildcard."$Z"+*.pem
    mkcert "*.$Z" "$Z" localhost
    for f in _wildcard."$Z"+*.pem; do
        case "$f" in
            *-key.pem) mv "$f" dvl.to.key ;;
            *)         mv "$f" dvl.to.pem ;;
        esac
    done
    cd ../../..
    {{engine}} compose restart nginx
    echo "Сертификат *.${Z} выпущен, nginx перезапущен"

# Скопировать AI.md в проект (для работы ИИ-ассистента внутри хоста)
ai name:
    cp AI.md hosts/{{name}}/AI.md && echo "AI.md → hosts/{{name}}/AI.md"

# Установка/обновление панели: зависимости, сборка, systemd-юнит
@panel-install:
    #!/usr/bin/env bash
    cd panel && npm install && npm run build
    PORT=$(grep '^PANEL_PORT=' ../.env | cut -d= -f2); PORT=${PORT:-8989}
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/devbox-panel.service <<UNIT
    [Unit]
    Description=DevBox Panel (SvelteKit)
    After=network.target

    [Service]
    WorkingDirectory=%h/Workspace/Server/panel
    Environment=NODE_ENV=production
    Environment=HOST=0.0.0.0
    Environment=PORT=${PORT}
    ExecStart=/usr/bin/node build
    Restart=on-failure
    RestartSec=3

    [Install]
    WantedBy=default.target
    UNIT
    sed -i 's/^    //' ~/.config/systemd/user/devbox-panel.service
    systemctl --user daemon-reload && systemctl --user enable --now devbox-panel.service
    echo "Панель: http://localhost (порт ${PORT})"

# Перезапуск панели (после правок кода + panel-install)
panel-restart:
    cd panel && npm run build && systemctl --user restart devbox-panel

# Логи панели
panel-logs:
    journalctl --user -u devbox-panel -f

# MySQL-клиент
sql:
    {{engine}} compose exec mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-root}"

# PostgreSQL-клиент
psql:
    {{engine}} compose exec postgres psql -U postgres

# Redis-клиент
redis:
    {{engine}} compose exec redis redis-cli

# Включить/выключить Xdebug в .env и перезапустить PHP-контейнеры
xdebug mode="debug":
    #!/usr/bin/env bash
    if [ "{{mode}}" = "off" ]; then sed -i 's/^XDEBUG_MODE=.*/XDEBUG_MODE=off/' .env; else sed -i 's/^XDEBUG_MODE=.*/XDEBUG_MODE={{mode}}/' .env; grep -q '^XDEBUG_MODE=' .env || echo "XDEBUG_MODE={{mode}}" >> .env; fi
    grep '^XDEBUG_MODE=' .env
    {{engine}} compose up -d php80 php82 php84
