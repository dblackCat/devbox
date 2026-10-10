# AI.md — как ИИ-ассистенту работать с проектом на этом хосте

Этот файл копируется в каталог проекта (см. README окружения, рецепт `just ai`).
Здесь — только взаимодействие с проектом: запуск кода, БД, почта, отладка.
Правила самой среды — в `~/Workspace/Server/AGENTS.md`, этот файл не редактировать.

## Что за окружение

Проект живёт в rootless-podman окружении DevBox (`~/Workspace/Server`):

- nginx + PHP-FPM (несколько версий) + MySQL + PostgreSQL + Redis + Manticore + Mailpit;
- каталог проекта на хосте `~/Workspace/Server/hosts/<project>/` смонтирован в контейнеры
  как `/var/www/<project>/` — правки файлов делаешь напрямую, перезапуск не нужен;
- сайт доступен по `http(s)://<project>.dvl.to` (cert локальный, mkcert).

## Выполнение команд

Все `podman compose` — из `~/Workspace/Server`. Пароль БД — из `~/Workspace/Server/.env`.

```bash
export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
cd ~/Workspace/Server

# версия php для этого проекта — смотреть fastcgi_pass в hosts/<project>/nginx.conf
podman compose exec -w /var/www/<project>/htdocs php82 composer install
podman compose exec -w /var/www/<project>/htdocs php82 php artisan migrate
podman compose exec -w /var/www/<project>/htdocs nodejs npm run build
```

sudo не использовать и не просить — окружение rootless.

## Базы данных

- MySQL: хост `mysql` (порт 3306), root, пароль `MYSQL_ROOT_PASSWORD` из `.env` окружения.
- PostgreSQL: хост `postgres` (5432), пользователь `postgres`, пароль `POSTGRES_PASSWORD`.
- Redis: `redis:6379`. Поиск: `manticore:9306` (SQL) / `:9308` (HTTP).

```bash
cd ~/Workspace/Server
podman exec server-mysql-1 mysql -uroot -p"$(grep ^MYSQL_ROOT_PASSWORD .env | cut -d= -f2)" <db> -e '...'
podman exec server-postgres-1 psql -U postgres -c '\l'
```

Из кода проекта подключаться по сетевым alias'ам (`mysql`, `db`, `postgres`, `pg`, `redis`), не по localhost.

## Почта

Вся почта в dev перехватывается Mailpit: SMTP `mailpit:1025` (без авторизации),
просмотр — http://localhost:8025. Реальных писем среда не отправляет.

## Панель управления

http://localhost (тёмная, SvelteKit): статус/логи контейнеров, реквизиты сервисов,
создание хостов, управление окружением. Код в `panel/`, конвенции — `panel/AGENTS.md`.
Рецепты: `just panel-install` / `panel-restart` / `panel-logs`.

## Отладка (Xdebug)

Установлен во всех php-контейнерах, по умолчанию выключен. Для CLI-скриптов:

```bash
podman compose exec -w /var/www/<project>/htdocs php82 env XDEBUG_MODE=debug php script.php
```

IDE слушает 9003, подключится автоматически (idekey `PHPSTORM`).

## Проверка сайта изнутри контейнеров

Домены `*.dvl.to` резолвятся изнутри сети — вебхуки/интеграции между проектами
тестируются обычными URL:

```bash
podman compose exec php82 php -r 'var_dump(@file_get_contents("https://<other>.dvl.to/"));'
```

## Частые ошибки

- **502 от nginx** — пересоздавались php-контейнеры, у nginx устарел IP upstream:
  `cd ~/Workspace/Server && podman compose restart nginx`.
- **Permission denied на запись** — файл принадлежит не пользователю; сообщи владельцу,
  chown сам сделать не можешь (sudo нет).
- **Ошибки приложения при пустой БД** — сверить, залит ли дамп (логи: `logs/php<ver>/` на хосте).
