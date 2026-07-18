#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

_find_container() {
    local search_name="$1"
    local container_name
    
    if [[ -z "$search_name" ]]; then
        echo "Ошибка: Не указано имя контейнера" >&2
        return 1
    fi
    
    if [[ "$search_name" == server-* ]]; then
        container_name="$search_name"
    else
        container_name=$(sudo podman ps --format "{{.Names}}" 2>/dev/null | grep -E "server-.*${search_name}.*-1" | head -1)
        
        if [[ -z "$container_name" ]]; then
            container_name=$(sudo podman ps --format "{{.Names}}" 2>/dev/null | grep -E "${search_name}" | head -1)
        fi
    fi
    
    if [[ -z "$container_name" ]]; then
        echo "Ошибка: Контейнер '$search_name' не найден" >&2
        echo "Доступные контейнеры:" >&2
        dv-show >&2
        return 1
    fi
    
    echo "$container_name"
}

_get_short_name() {
    local full_name="$1"
    local short_name="${full_name#server-}"
    short_name="${short_name%-1}"
    echo "$short_name"
}

dv-start() {
    cd "$PROJECT_ROOT" && sudo podman compose up -d
}

dv-stop() {
    cd "$PROJECT_ROOT" && sudo podman compose down
}

dv-build() {
    cd "$PROJECT_ROOT" && sudo podman compose down && sudo podman compose build --no-cache
}

dv-restart() {
    cd "$PROJECT_ROOT" && sudo podman compose down && sudo podman compose up -d
}

dv-show() {
    echo "Доступные контейнеры:"
    echo "====================="
    
    local CONTAINERS=$(sudo podman ps --format "{{.Names}}" 2>/dev/null)
    
    if [ -z "$CONTAINERS" ]; then
        echo "Нет запущенных контейнеров."
        echo "Запустите окружение командой: dv-start"
        return 1
    fi
    
    while IFS= read -r container; do
        echo "$(_get_short_name "$container")"
    done <<< "$CONTAINERS" | sort
    
    echo "=============================="
}

dv-run() {
    local ORIGINAL_DIR="$(pwd)"
    
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Ошибка: Не указан контейнер или команда"
        echo "Использование: dv-run <контейнер> <команда> [аргументы...]"
        echo "Пример: dv-run php82 composer install"
        echo "Пример: dv-run nodejs npm run build"
        echo "Пример: dv-run php ls -la"
        echo ""
        echo "Доступные контейнеры:"
        dv-show
        return 1
    fi

    local SEARCH_NAME="$1"
    shift
    
    local CONTAINER_NAME
    CONTAINER_NAME="$(_find_container "$SEARCH_NAME")"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    cd "$PROJECT_ROOT"

    local WORKDIR="/var/www"
    if [[ "$ORIGINAL_DIR" =~ /hosts/(.+) ]]; then
        WORKDIR="/var/www/${BASH_REMATCH[1]}"
    fi
    
    local SHORT_NAME="$(_get_short_name "$CONTAINER_NAME")"
    
    echo "Запуск в контейнере $SHORT_NAME ($CONTAINER_NAME): $@"
    echo "Рабочая директория: $WORKDIR"
    sudo podman exec -w "$WORKDIR" "$CONTAINER_NAME" "$@"
    
    cd "$ORIGINAL_DIR"
}

dv-logs() {
    local ORIGINAL_DIR="$(pwd)"
    
    if [ -z "$1" ]; then
        echo "Ошибка: Не указано название контейнера"
        echo "Использование: dv-logs <название_контейнера> [--follow]"
        echo "Пример: dv-logs nginx --follow"
        echo "Пример: dv-logs php82"
        echo ""
        echo "Доступные контейнеры:"
        dv-show
        return 1
    fi
    
    local SEARCH_NAME="$1"
    
    local CONTAINER_NAME
    CONTAINER_NAME="$(_find_container "$SEARCH_NAME")"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    local SHORT_NAME="$(_get_short_name "$CONTAINER_NAME")"
    FOLLOW_FLAG=""
    if [ "$2" = "--follow" ]; then
        FOLLOW_FLAG="-f"
    fi
    
    echo "Просмотр логов контейнера: $SHORT_NAME ($CONTAINER_NAME)"
    sudo podman logs $FOLLOW_FLAG "$CONTAINER_NAME"
    
    cd "$ORIGINAL_DIR"
}

dv-open() {
    local ORIGINAL_DIR="$(pwd)"
    
    if [ -z "$1" ]; then
        echo "Ошибка: Не указано название контейнера"
        echo "Использование: dv-open <название_контейнера>"
        echo "Пример: dv-open php82"
        echo "Пример: dv-open nginx"
        echo ""
        echo "Доступные контейнеры:"
        dv-show
        return 1
    fi
 
    local SEARCH_NAME="$1"
    
    local CONTAINER_NAME
    CONTAINER_NAME="$(_find_container "$SEARCH_NAME")"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    local WORKDIR="/var/www"
    if [[ "$ORIGINAL_DIR" =~ /hosts/(.+) ]]; then
        WORKDIR="/var/www/${BASH_REMATCH[1]}"
    fi
    
    local SHORT_NAME="$(_get_short_name "$CONTAINER_NAME")"
    
    echo "Подключаемся к контейнеру: $SHORT_NAME ($CONTAINER_NAME)"
    echo "Рабочая директория: $WORKDIR"
    
    sudo podman exec -w "$WORKDIR" -it "$CONTAINER_NAME" /bin/bash
    
    cd "$ORIGINAL_DIR"
}

dv-host() {
    local ORIGINAL_DIR="$(pwd)"
    
    if [ -z "$1" ]; then
        echo "Ошибка: Не указано название хоста"
        echo "Использование: dv-host <название_хоста> [--php<версия>]"
        echo "Пример: dv-host my-host --php74"
        cd "$ORIGINAL_DIR"
        return 1
    fi

    cd "$PROJECT_ROOT"
    
    if [ ! -f .env ]; then
        echo "Ошибка: Файл .env не найден. Создайте его с переменными HOST_ZONE и DEFAULT_PHP_VERSION."
        cd "$ORIGINAL_DIR"
        return 1
    fi

    source .env

    PHP_VERSION="$DEFAULT_PHP_VERSION"
    if [[ "$2" =~ ^--php([0-9]+)$ ]]; then
        PHP_VERSION="php${BASH_REMATCH[1]}"
    fi

    FASTCGI_PORT=9000

    HOST_DIR="hosts/$1"
    if [ -d "$HOST_DIR" ]; then
        echo "Ошибка: Директория $HOST_DIR уже существует"
        cd "$ORIGINAL_DIR"
        return 1
    fi

    mkdir -p "$HOST_DIR/htdocs"

    cat > "$HOST_DIR/nginx.conf" << EOF
server {
	listen 80;
	server_name $1.$HOST_ZONE;
	root /var/www/$1/htdocs;
	index index.php index.html;

	location / {
		try_files \$uri \$uri/ /index.php?\$query_string;
	}

	location ~ \.php\$ {
		fastcgi_pass $PHP_VERSION:$FASTCGI_PORT;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_param PATH_INFO \$fastcgi_path_info;
	}
}
EOF

    echo "Хост $1 создан в директории $HOST_DIR"
    echo "nginx.conf сгенерирован с server_name $1.$HOST_ZONE и PHP версией $PHP_VERSION"
    
    cd "$ORIGINAL_DIR"
}

dv-help() {
    echo "Доступные команды для управления окружением devbox:"
    echo "  dv-start   - Запуск окружения"
    echo "  dv-stop    - Остановка окружения"
    echo "  dv-restart - Перезапуск окружения"
    echo "  dv-build   - Пересборка контейнеров"
    echo "  dv-show    - Показать доступные контейнеры"
    echo "  dv-run <контейнер> <команда> - Запуск команды в контейнере"
    echo "  dv-open <название> - Вход в контейнер"
    echo "  dv-host <название> [--php<версия>] - Создание нового хоста"
    echo "  dv-logs <название> [--follow] - Просмотр логов контейнера"
    echo "  dv-help    - Показать эту справку"
    echo ""
    echo "Примеры использования dv-run и dv-open:"
    echo "  dv-run php82 artisan migrate    # Использует контейнер server-php82-1"
    echo "  dv-run php composer install     # Находит любой PHP контейнер"
    echo "  dv-run nodejs npm run dev       # Использует контейнер server-nodejs-1"
    echo "  dv-open php82                   # Вход в контейнер php82"
    echo "  dv-open nginx                   # Вход в контейнер nginx"
    echo ""
    echo "Автоматическое определение рабочей директории:"
    echo "  При запуске из ~/Workspace/Server/hosts/cd-svelte/htdocs"
    echo "  Рабочая директория будет: /var/www/cd-svelte/htdocs"
    echo ""
    echo "Для просмотра доступных контейнеров: dv-show"
}

export -f dv-start
export -f dv-stop
export -f dv-restart
export -f dv-build
export -f dv-show
export -f dv-run
export -f dv-open
export -f dv-host
export -f dv-logs
export -f dv-help
