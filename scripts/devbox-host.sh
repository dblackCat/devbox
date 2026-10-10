#!/bin/bash
# Создание нового хоста: devbox-host.sh <name> [php82|php80|...]
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [ -z "$1" ]; then
    echo "Использование: $0 <название_хоста> [php-версия, по умолчанию php82]" >&2
    exit 1
fi

[ -f .env ] || { echo "Ошибка: .env не найден" >&2; exit 1; }
source .env

NAME="$1"
PHP_VERSION="${2:-php82}"
HOST_ZONE="${HOST_ZONE:-dvl.to}"
HOST_DIR="hosts/$NAME"

[ -d "$HOST_DIR" ] && { echo "Ошибка: $HOST_DIR уже существует" >&2; exit 1; }

mkdir -p "$HOST_DIR/htdocs"

cat > "$HOST_DIR/nginx.conf" << EOF
server {
	listen 80;
	listen 443 ssl;
	ssl_certificate /etc/nginx/ssl/dvl.to.pem;
	ssl_certificate_key /etc/nginx/ssl/dvl.to.key;
	server_name $NAME.$HOST_ZONE;
	root /var/www/$NAME/htdocs;
	index index.php index.html;

	location / {
		try_files \$uri \$uri/ /index.php?\$query_string;
	}

	location ~ \.php\$ {
		fastcgi_pass $PHP_VERSION:9000;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_param PATH_INFO \$fastcgi_path_info;
	}
}
EOF

echo "Хост $NAME.$HOST_ZONE создан в $HOST_DIR (PHP: $PHP_VERSION)"

# обновить сетевые алиасы *.dvl.to
"$PROJECT_ROOT/scripts/sync-hosts.sh"
