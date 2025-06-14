
FROM php:8.0-fpm

# Установка инструментов от root
USER root

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    libicu-dev \
    libpq-dev \
    librabbitmq-dev \
    gettext \
    libmemcached-dev \
    libsasl2-dev \
    git \
    curl \
    zip \
    unzip \
    nano \
    mc \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Установка GD с поддержкой WebP
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    && docker-php-ext-install -j$(nproc) gd

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

# Установка Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Настройка пользователя
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} dev && \
    useradd -u ${USER_ID} -g dev -m dev && \
    chown -R dev:dev /var/www

# Переключение на пользователя
USER dev
WORKDIR /var/www

COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zzz-custom.conf

CMD ["php-fpm"] 