#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# Функция для получения списка контейнеров
dv-show() {
    echo "Доступные контейнеры:"
    echo "====================="
    
    # Получаем список всех запущенных контейнеров
    local CONTAINERS=$(sudo podman ps --format "{{.Names}}" 2>/dev/null)
    
    if [ -z "$CONTAINERS" ]; then
        echo "Нет запущенных контейнеров."
        echo "Запустите окружение командой: dv-start"
        return 1
    fi
    
    # Извлекаем базовые имена контейнеров (убираем префикс и номер)
    echo "$CONTAINERS" | sed -E 's/server-([a-zA-Z0-9]+)-[0-9]+/\1/' | sort | uniq | while read -r container; do
        # Считаем количество экземпляров каждого контейнера
        local count=$(echo "$CONTAINERS" | grep -c "server-${container}-")
        echo "  $container ($count экземпляр(а/ов))"
    done
    
    echo ""
    echo "Все контейнеры (полные имена):"
    echo "=============================="
    echo "$CONTAINERS" | sort
    
    echo ""
    echo "Для просмотра всех контейнеров (включая остановленные):"
    echo "  sudo podman ps -a"
}

# Функция для получения полного имени контейнера по короткому имени
_get_container_full_name() {
    local short_name="$1"
    local full_name=$(sudo podman ps --format "{{.Names}}" | grep -E "server-${short_name}-[0-9]+" | head -1)
    echo "$full_name"
}

# Функция для проверки существования контейнера
_check_container_exists() {
    local short_name="$1"
    local full_name=$(_get_container_full_name "$short_name")
    
    if [ -z "$full_name" ]; then
        echo "Ошибка: Контейнер с именем '$short_name' не найден или не запущен"
        return 1
    fi
    
    return 0
}

dv-run() {
    local ORIGINAL_DIR="$(pwd)"
    
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Ошибка: Не указан контейнер или команда"
        echo "Использование: dv-run <контейнер> <команда> [аргументы...]"
        echo "Пример: dv-run php82 artisan migrate"
        echo "Пример: dv-run nodejs npm run build"
        echo "Пример: dv-run php82 composer install"
        return 1
    fi

    local CONTAINER="$1"
    shift
    local COMMAND="$@"
    
    # Проверяем существование контейнера
    if ! _check_container_exists "$CONTAINER"; then
        echo ""
        dv-show
        cd "$ORIGINAL_DIR"
        return 1
    fi
    
    # Получаем полное имя контейнера
    local CONTAINER_NAME=$(_get_container_full_name "$CONTAINER")
    
    cd "$PROJECT_ROOT"

    local WORKDIR="/var/www"
    
    if [[ "$ORIGINAL_DIR" =~ /hosts/(.+) ]]; then
        WORKDIR="/var/www/${BASH_REMATCH[1]}"
        echo "Рабочая директория: $WORKDIR"
    else
        echo "Предупреждение: Команда вызвана не из папки hosts/, используется /var/www"
    fi

    echo "Запуск в контейнере $CONTAINER_NAME: $COMMAND"
    sudo podman exec -w "$WORKDIR" "$CONTAINER_NAME" $COMMAND
    
    cd "$ORIGINAL_DIR"
}

dv-logs() {
    local ORIGINAL_DIR="$(pwd)"
    
    if [ -z "$1" ]; then
        echo "Ошибка: Не указано название контейнера"
        echo "Использование: dv-logs <название_контейнера> [--follow]"
        echo "Пример: dv-logs nginx --follow"
        echo "Имена контейнеров соответствуют конфигурации docker-compose"
        return 1
    fi

    # Проверяем существование контейнера
    if ! _check_container_exists "$1"; then
        echo ""
        dv-show
        cd "$ORIGINAL_DIR"
        return 1
    fi
    
    # Получаем полное имя контейнера
    local CONTAINER_NAME=$(_get_container_full_name "$1")
    
    cd "$PROJECT_ROOT"
    
    FOLLOW_FLAG=""
    if [ "$2" = "--follow" ]; then
        FOLLOW_FLAG="-f"
    fi
    
    echo "Просмотр логов контейнера: $CONTAINER_NAME"
    sudo podman logs $FOLLOW_FLAG "$CONTAINER_NAME"
    
    cd "$ORIGINAL_DIR"
}

dv-open() {
    local ORIGINAL_DIR="$(pwd)"
    
    if [ -z "$1" ]; then
        echo "Ошибка: Не указано название контейнера"
        echo "Использование: dv-open <название_контейнера>"
        echo "Пример: dv-open php74|php80|php82|nodejs"
        echo "Имена контейнеров соответствуют конфигурации docker-compose"
        return 1
    fi
    
    # Проверяем существование контейнера
    if ! _check_container_exists "$1"; then
        echo ""
        dv-show
        cd "$ORIGINAL_DIR"
        return 1
    fi
    
    # Получаем полное имя контейнера
    local CONTAINER_NAME=$(_get_container_full_name "$1")
    
    cd "$PROJECT_ROOT"
    
    echo "Подключаемся к контейнеру: $CONTAINER_NAME"
    sudo podman exec -it "$CONTAINER_NAME" /bin/bash
    
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

# Функция для вывода справки
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
    echo "Примеры использования dv-run:"
    echo "  dv-run php82 artisan migrate"
    echo "  dv-run nodejs npm run dev"
    echo "  dv-run php82 composer install"
    echo "  dv-run php82 ls -la"
    echo ""
    echo "Для просмотра доступных контейнеров: dv-show"
}

# Экспортируем функции
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
