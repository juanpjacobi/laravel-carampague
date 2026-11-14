FROM php:8.1-cli-alpine

# Dependencias del sistema: cliente mysql (para cargar database/schema/mysql-schema.sql),
# librerías para gd (dompdf), zip e intl.
RUN apk add --no-cache \
        mysql-client \
        git unzip \
        libpng-dev libjpeg-turbo-dev freetype-dev \
        libzip-dev icu-dev oniguruma-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql gd zip intl bcmath mbstring opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Primero las dependencias, para aprovechar la cache de capas.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist \
        --optimize-autoloader --no-scripts

COPY . .

RUN composer dump-autoload --optimize --no-dev \
    && chmod +x docker/start.sh \
    && chmod -R 775 storage bootstrap/cache

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr

EXPOSE 8080

CMD ["sh", "docker/start.sh"]
