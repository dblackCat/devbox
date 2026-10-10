FROM php:8.0-fpm

# bullseye в архиве — переключаемся на archive.debian.org
RUN sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g; /bullseye-updates/d' /etc/apt/sources.list \
    && sed -i '/security/d' /etc/apt/sources.list

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
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    && docker-php-ext-install -j$(nproc) gd

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

RUN pecl install xdebug && docker-php-ext-enable xdebug

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www

COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zzz-custom.conf
COPY xdebug.ini /usr/local/etc/php/conf.d/zz-xdebug.ini

CMD ["php-fpm", "-R"]
