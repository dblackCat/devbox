#!/bin/bash

# Определяем путь к корневой директории проекта
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Функции для управления окружением devbox
devbox-start() {
    cd "$PROJECT_ROOT" && sudo podman compose up -d
}

devbox-stop() {
    cd "$PROJECT_ROOT" && sudo podman compose down
}

devbox-build() {
    cd "$PROJECT_ROOT" && sudo podman compose down && sudo podman compose build --no-cache
}

devbox-restart() {
    cd "$PROJECT_ROOT" && sudo podman compose down && sudo podman compose up -d
}

# Функция для просмотра логов
devbox-logs() {
    if [ -z "$1" ]; then
        echo "Ошибка: Не указано название контейнера"
        echo "Использование: devbox-logs <название_контейнера> [--follow]"
        echo "Пример: devbox-logs nginx --follow"
        echo "Доступные контейнеры: nginx, php74, php80, php82, mysql, phpmyadmin"
        return 1
    fi

    cd "$PROJECT_ROOT"
    
    # Получаем список контейнеров и ищем нужный
    CONTAINER_NAME=$(sudo podman ps --format "{{.Names}}" | grep -E "server-${1}-[0-9]+")
    
    if [ -z "$CONTAINER_NAME" ]; then
        echo "Ошибка: Контейнер с именем $1 не найден"
        echo "Доступные контейнеры:"
        sudo podman ps --format "{{.Names}}"
        return 1
    fi
    
    # Если указан флаг --follow, добавляем его к команде
    FOLLOW_FLAG=""
    if [ "$2" = "--follow" ]; then
        FOLLOW_FLAG="-f"
    fi
    
    echo "Просмотр логов контейнера: $CONTAINER_NAME"
    sudo podman logs $FOLLOW_FLAG "$CONTAINER_NAME"
}

# Функция для входа в контейнер
devbox-container() {
    if [ -z "$1" ]; then
        echo "Ошибка: Не указано название контейнера"
        echo "Использование: devbox-container <название_контейнера>"
        echo "Пример: devbox-container php74|php80|php82"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # Получаем список контейнеров и ищем нужный
    CONTAINER_NAME=$(sudo podman ps --format "{{.Names}}" | grep -E "server-${1}-[0-9]+")
    
    if [ -z "$CONTAINER_NAME" ]; then
        echo "Ошибка: Контейнер с именем $1 не найден"
        echo "Доступные контейнеры:"
        sudo podman ps --format "{{.Names}}"
        return 1
    fi
    
    echo "Подключаемся к контейнеру: $CONTAINER_NAME"
    sudo podman exec -it "$CONTAINER_NAME" /bin/bash
}

# Функция для создания нового хоста
devbox-host() {
    if [ -z "$1" ]; then
        echo "Ошибка: Не указано название хоста"
        echo "Использование: devbox-host <название_хоста> [--php<версия>]"
        echo "Пример: devbox-host my-host --php74"
        return 1
    fi

    cd "$PROJECT_ROOT"
    
    # Проверяем, существует ли .env
    if [ ! -f .env ]; then
        echo "Ошибка: Файл .env не найден. Создайте его с переменными HOST_ZONE и DEFAULT_PHP_VERSION."
        return 1
    fi

    # Загружаем переменные из .env
    source .env

    # Определяем версию PHP
    PHP_VERSION="$DEFAULT_PHP_VERSION"
    if [[ "$2" =~ ^--php([0-9]+)$ ]]; then
        PHP_VERSION="php${BASH_REMATCH[1]}"
    fi

    # Определяем порт для fastcgi
    FASTCGI_PORT=9000

    # Создаём директорию хоста
    HOST_DIR="hosts/$1"
    if [ -d "$HOST_DIR" ]; then
        echo "Ошибка: Директория $HOST_DIR уже существует"
        return 1
    fi

    mkdir -p "$HOST_DIR/htdocs"

    # Генерируем nginx.conf
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
}

# Функция для вывода справки
devbox-help() {
    echo "Доступные команды для управления окружением devbox:"
    echo "  devbox-start   - Запуск окружения"
    echo "  devbox-stop    - Остановка окружения"
    echo "  devbox-restart - Перезапуск окружения"
    echo "  devbox-container <название> - Вход в контейнер"
    echo "  devbox-host <название> [--php<версия>] - Создание нового хоста"
    echo "  devbox-logs <название> [--follow] - Просмотр логов контейнера"
    echo "  devbox-help    - Показать эту справку"
}

# Экспортируем функции
export -f devbox-start
export -f devbox-stop
export -f devbox-restart
export -f devbox-container
export -f devbox-host
export -f devbox-logs
export -f devbox-help 