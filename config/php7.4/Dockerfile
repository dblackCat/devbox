FROM php:8.0-fpm-alpine

# Установка инструментов от root
USER root

# Установка зависимостей
RUN apk add \
    $PHPIZE_DEPS \
    linux-headers \
    curl \
    zip \
    unzip \
    nano \
    mc \
    bash \
    npm \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    oniguruma-dev \
    icu-dev \
    postgresql-dev \
    rabbitmq-c-dev \
    gettext-dev \
    libmemcached-dev \
    cyrus-sasl-dev \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS

# Установка базовых расширений
RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    calendar \
    exif \
    gettext \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    soap \
    sockets \
    zip

# Установка GD
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd

# Установка Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Настройка пользователя
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN addgroup -g ${GROUP_ID} dev && \
    adduser -D -u ${USER_ID} -G dev dev && \
    chown -R dev:dev /var/www


# Очистка
RUN apk del .build-deps

# Переключение на пользователя
USER dev
WORKDIR /var/www

COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zzz-custom.conf