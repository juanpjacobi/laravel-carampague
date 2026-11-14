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

# El cliente mysql (MariaDB) exige verificar el certificado TLS y rechaza el
# autofirmado de Railway. La red interna de Railway es privada, asi que se
# desactiva TLS para el cliente CLI que Laravel usa al cargar el schema dump.
RUN mkdir -p /etc/my.cnf.d \
    && printf '[client]\nskip-ssl\nssl-verify-server-cert=0\n' > /etc/my.cnf.d/99-no-ssl.cnf \
    && grep -q 'my.cnf.d' /etc/my.cnf 2>/dev/null || printf '!includedir /etc/my.cnf.d\n' >> /etc/my.cnf

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
